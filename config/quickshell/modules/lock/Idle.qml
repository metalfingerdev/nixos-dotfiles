pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.services

// What hypridle would do, inside the shell. Each step counts from the last input:
//   dim      the backlight drops to dimTo %, and comes back on input
//   lock     the lock screen (input doesn't undo this one)
//   off      the screens go off, and come back on input
//   suspend  the machine sleeps
// A step doesn't run while something inhibits idling: a Wayland inhibitor (a fullscreen video) or a
// logind one (`systemd-inhibit --what=idle`, the dashboard's Caffeine). One skipped this way waits
// for the next time the session goes idle, as in hypridle.
//
// Whatever puts the machine to sleep (the suspend step, the lid, `systemctl suspend`), the screen
// locks first, and `loginctl lock-session` locks it too. Nothing here unlocks: only the password does.
//   qs ipc call idle enable false          stop the steps (the lock before sleep stays)
//   qs ipc call idle toggle
//   qs ipc call idle set lock 600          a step's seconds; 0 = never
//   qs ipc call idle dimTo 10              how far the dim step goes, in percent
//   qs ipc call idle status                all of those, and the steps that have run, as JSON
// views/Settings.qml sets the same things.
Singleton {
	id: root

	// WlSessionLock.secure: the compositor says every screen is covered
	property bool secure: false
	signal lockRequested()

	// ---- remembered across restarts ----
	property bool enabled: true
	property int dimAfter: 150
	property int lockAfter: 300
	property int offAfter: 330
	property int suspendAfter: 1800
	property int dimTo: 10

	// ~/.local/state/quickshell/island.ini, like the island's settings
	property Settings store: Settings {
		location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
		category: "idle"
		property alias enabled: root.enabled
		property alias dimAfter: root.dimAfter
		property alias lockAfter: root.lockAfter
		property alias offAfter: root.offAfter
		property alias suspendAfter: root.suspendAfter
		property alias dimTo: root.dimTo
	}

	// ---- the steps ----
	component Step: IdleMonitor {
		property string name: ""
		property int after: 0        // seconds; 0 = never
		property bool done: false    // it ran, and input hasn't undone it yet
		property bool armed: true
		signal run()
		signal undo()

		timeout: after
		enabled: root.enabled && after > 0 && armed
		// IdleMonitor ignores a new timeout until it's turned off and on again.
		onTimeoutChanged: {
			armed = false;
			armed = true;
		}
		onIsIdleChanged: {
			if (isIdle) {
				inhibitCheck.running = true;
			} else if (done) {
				done = false;
				undo();
			}
		}
	}

	property int dimmedFrom: -1

	Step {
		id: dimStep
		name: "dim"
		after: root.dimAfter
		onRun: {
			if (Backlight.percent <= root.dimTo) return;
			root.dimmedFrom = Backlight.percent;
			Backlight.set(root.dimTo);
		}
		onUndo: {
			if (root.dimmedFrom < 0) return;
			Backlight.set(root.dimmedFrom);
			root.dimmedFrom = -1;
		}
	}

	Step {
		id: lockStep
		name: "lock"
		after: root.lockAfter
		onRun: root.lockRequested();
	}

	Step {
		id: offStep
		name: "off"
		after: root.offAfter
		onRun: root.screens(false);
		onUndo: root.screens(true);
	}

	Step {
		id: suspendStep
		name: "suspend"
		after: root.suspendAfter
		onRun: Session.run("suspend");
	}

	readonly property var steps: [dimStep, lockStep, offStep, suspendStep]
	readonly property bool screensOff: offStep.done

	// Exactly "on" or "off": Hyprland reads any other action as a toggle.
	function screens(on) {
		const action = on ? "on" : "off";
		Desktops.dispatch(`hl.dsp.dpms({ action = "${action}" })`, `dpms ${action}`);
	}

	// logind has no signal for its inhibitors, so ask when a step comes due. It answers `s "idle:sleep"`.
	Process {
		id: inhibitCheck
		command: ["busctl", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1",
			"org.freedesktop.login1.Manager", "BlockInhibited"]
		stdout: StdioCollector {
			onStreamFinished: {
				if (/\bidle\b/.test(text)) return;

				for (const step of root.steps) {
					if (step.isIdle && !step.done) {
						step.done = true;
						step.run();
					}
				}
			}
		}
	}

	// ---- the lock before sleep, and logind's own lock request ----
	property bool goingToSleep: false

	// Holds the sleep back until the screen is locked, or nothing would be covered when it wakes.
	// logind waits at most InhibitDelayMaxSec (5 s by default).
	Process {
		running: !root.goingToSleep || !root.secure
		command: ["systemd-inhibit", "--what=sleep", "--who=Island", "--why=Locks the screen first", "--mode=delay",
			"sleep", "infinity"]
	}

	property string signalName: ""

	// One signal is two lines: a header ending in `member=PrepareForSleep`, then `   boolean true`.
	function readLogind(line) {
		const header = line.match(/member=(\w+)$/);
		if (header) {
			signalName = header[1];
			if (signalName === "Lock") lockRequested();
		} else if (signalName === "PrepareForSleep" && line.includes("boolean")) {
			goingToSleep = line.includes("true");
			if (goingToSleep) lockRequested();
			else screens(true);
		}
	}

	Process {
		id: logind
		running: true
		command: ["dbus-monitor", "--system",
			"type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'",
			"type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Session',member='Lock'"]
		stdout: SplitParser { onRead: line => root.readLogind(line) }
		onRunningChanged: if (!running) restartLogind.start();
	}

	// without it nothing locks before sleep, so it comes back if the bus goes away
	Timer {
		id: restartLogind
		interval: 5000
		onTriggered: logind.running = true;
	}

	IpcHandler {
		target: "idle"

		function enable(on: bool): void { root.enabled = on; }
		function toggle(): void { root.enabled = !root.enabled; }
		function set(step: string, seconds: int): string {
			const key = ({ dim: "dimAfter", lock: "lockAfter", off: "offAfter", suspend: "suspendAfter" })[step];
			if (!key) return `unknown step: ${step} (dim, lock, off, suspend)`;
			root[key] = Math.max(0, seconds);
			return "";
		}
		function dimTo(percent: int): void { root.dimTo = Math.max(1, Math.min(100, percent)); }
		function status(): string {
			return JSON.stringify({
				enabled: root.enabled,
				dim: root.dimAfter,
				lock: root.lockAfter,
				off: root.offAfter,
				suspend: root.suspendAfter,
				dimTo: root.dimTo,
				ran: root.steps.filter(step => step.done).map(step => step.name)
			}, null, 2);
		}
	}
}
