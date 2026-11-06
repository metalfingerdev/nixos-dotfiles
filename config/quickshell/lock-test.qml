import QtQuick
import Quickshell
import qs.modules.lock

// Try the lock screen in a normal window, without locking anything:
//   qs -p lock-test.qml
// It lives at the root because a shell's root is the folder of the file it runs: from modules/lock,
// the surface's `qs.*` imports wouldn't resolve. The right password quits; so does closing the window.
ShellRoot {
	LockContext {
		id: lockContext
		onUnlocked: Qt.quit();
	}

	FloatingWindow {
		LockSurface {
			anchors.fill: parent
			context: lockContext
		}
	}

	Connections {
		target: Quickshell

		function onLastWindowClosed() {
			Qt.quit();
		}
	}
}
