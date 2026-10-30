import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.services

// The lock screen: a session lock with a LockSurface on every screen, all sharing one LockContext
// (what's typed, PAM, the failure message). Only the password unlocks it (PAM: pam/password.conf).
//   qs ipc call lock screen
//   Session.run("lock")   the Power view's Lock tile, the launcher's Lock
// Try it in a window first, without locking anything: qs -p modules/lock/test.qml
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

	WlSessionLock {
		id: session

		// one per screen
		WlSessionLockSurface {
			LockSurface {
				anchors.fill: parent
				context: lockContext
			}
		}
	}

	Connections {
		target: Session
		function onLockRequested() { root.lock(); }
	}

	IpcHandler {
		target: "lock"

		function screen(): void { root.lock(); }
	}
}
