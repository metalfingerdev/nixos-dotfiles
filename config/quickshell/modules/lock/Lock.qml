import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.services

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

	Binding { target: Idle; property: "secure"; value: session.secure }

	WlSessionLock {
		id: session

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
