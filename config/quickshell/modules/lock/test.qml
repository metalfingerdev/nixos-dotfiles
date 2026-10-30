import QtQuick
import Quickshell

// Try the lock screen in a normal window, without locking anything:
//   qs -p modules/lock/test.qml
// The right password quits; so does closing the window.
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

	// exit the example if the window closes
	Connections {
		target: Quickshell

		function onLastWindowClosed() {
			Qt.quit();
		}
	}
}
