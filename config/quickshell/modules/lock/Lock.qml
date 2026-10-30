import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.services

// The lock screen: a session lock with a LockSurface on every screen, all sharing one LockContext
// (what's typed, PAM, the failure message) and LockConfig (what it shows). Only the password unlocks it (PAM: pam/password.conf).
//   qs ipc call lock screen
//   Session.run("lock")   the Power view's Lock tile, the launcher's Lock
//   qs ipc call lock image /path/to/picture.png    the background ("" = the wallpaper)
//   qs ipc call lock avatar /path/to/face.gif      the profile picture, GIFs play ("" = a person glyph)
//   qs ipc call lock avatarShape square            its frame: circle | square
//   qs ipc call lock name "Some Name"              the name shown ("" = the full name in passwd)
//   qs ipc call lock info "Back at 3"              the line under it ("" = user@host)
//   qs ipc call lock status                        all of those, as JSON
// Try it in a window first, without locking anything: qs -p lock-test.qml
Scope {
	id: root

	readonly property bool locked: session.locked

	function lock() {
		if (session.locked) return;
		lockContext.reset();
		session.locked = true;
	}

	LockContext {
		id: lockContext

		// Release the lock here, while the client still holds it: if quickshell let go any other
		// way (quitting, crashing), the compositor would show its fallback lock, which can't be unlocked.
		onUnlocked: session.locked = false;
	}

	// Idle locks after a while with no input, and before the machine sleeps
	Binding { target: Idle; property: "secure"; value: session.secure }

	WlSessionLock {
		id: session

		// one per screen
		WlSessionLockSurface {
			LockSurface {
				anchors.fill: parent
				context: lockContext
				animate: !Idle.screensOff
			}
		}
	}

	Connections {
		target: Session
		function onLockRequested() { root.lock(); }
	}

	Connections {
		target: Idle
		function onLockRequested() { root.lock(); }
	}

	IpcHandler {
		target: "lock"

		function screen(): void { root.lock(); }
		function image(path: string): string { return LockConfig.setPicture("image", path); }
		function avatar(path: string): string { return LockConfig.setPicture("avatar", path); }
		function avatarShape(shape: string): string {
			if (shape !== "circle" && shape !== "square") return `unknown shape: ${shape} (circle, square)`;
			LockConfig.avatarShape = shape;
			return "";
		}
		function name(text: string): void { LockConfig.name = text; }
		function info(text: string): void { LockConfig.info = text; }
		function status(): string {
			return JSON.stringify({
				locked: root.locked,
				image: LockConfig.image,
				avatar: LockConfig.avatar,
				avatarShape: LockConfig.avatarShape,
				name: LockConfig.shownName,
				info: LockConfig.shownInfo
			}, null, 2);
		}
	}
}
