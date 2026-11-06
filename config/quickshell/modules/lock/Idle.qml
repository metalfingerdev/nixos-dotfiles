pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.components
import qs.modules.services

// What hypridle would do, inside the shell (commands: docs/ipc.md).
// A step doesn't run while something inhibits idling: a Wayland inhibitor (a fullscreen video) or a
// logind one (`systemd-inhibit --what=idle`, the dashboard's Caffeine). One skipped this way waits
// for the next time the session goes idle, as in hypridle.
// Media counts as input: while it plays nothing counts down, and the wait starts over when it stops.
// Nothing here unlocks: only the password does.
Singleton {
	id: root

	// WlSessionLock.secure: the compositor says every screen is covered
	property bool secure: false
	signal lockRequested()

	property bool enabled: true
	property int dimAfter: 150
	property int lockAfter: 300
	property int offAfter: 330
	property int suspendAfter: 1800
	property int dimTo: 10

	readonly property bool mediaPlaying: Players.anyPlaying || Audio.playing

	property Store store: Store {
		category: "idle"
		property alias enabled: root.enabled
		property alias dimAfter: root.dimAfter
		property alias lockAfter: root.lockAfter
		property alias offAfter: root.offAfter
		property alias suspendAfter: root.suspendAfter
		property alias dimTo: root.dimTo
	}

	component Step: IdleMonitor {
		property string name: ""
		property int after: 0        // seconds; 0 = never
		property bool done: false    // it ran, and input hasn't undone it yet
		property bool armed: true
		signal run()
		signal undo()

		timeout: after
		// Turned off it isn't idle, and turned on it counts from then: just what input does.
		enabled: root.enabled && after > 0 && armed && !root.mediaPlaying
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
				media: root.mediaPlaying,
				ran: root.steps.filter(step => step.done).map(step => step.name)
			}, null, 2);
		}
	}
}
