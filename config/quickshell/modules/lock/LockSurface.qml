import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

// One screen of the lock: the picture, the clock, who is locked out, the password field. What it
// shows comes from LockConfig and what's typed from the LockContext, so every screen matches.
Rectangle {
	id: root
	required property LockContext context

	// the plain colour shows until the picture loads, and for good if there is no picture
	color: Config.surface

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	Image {
		id: background
		// the lock image, or the wallpaper if there is none or it can't be loaded (it moved, say)
		property string broken: ""
		readonly property string path: LockConfig.image !== "" && LockConfig.image !== broken ? LockConfig.image : Wallpaper.current

		anchors.fill: parent
		source: path ? Wallpaper.fileUrl(path) : ""
		sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
		fillMode: Image.PreserveAspectCrop
		asynchronous: true
		opacity: status === Image.Ready ? 1 : 0
		onStatusChanged: if (status === Image.Error) broken = LockConfig.image;

		Behavior on opacity { NumberAnimation { duration: 200 } }
	}

	Column {
		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			topMargin: parent.height * 0.1
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Qt.formatDateTime(clock.date, "HH:mm")
			color: Config.text
			// The native font renderer tends to look nicer at large sizes.
			renderType: Text.NativeRendering
			font.family: Config.font
			font.pixelSize: 112
			font.weight: Font.Medium
			font.features: { "tnum": 1 }
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
			color: Config.text
			font.family: Config.font
			font.pixelSize: Config.title
		}
	}

	Column {
		// Uncommenting this will make the password entry invisible except on the active monitor.
		// visible: Window.active

		anchors {
			horizontalCenter: parent.horizontalCenter
			verticalCenter: parent.verticalCenter
			verticalCenterOffset: parent.height * 0.08
		}
		width: 380
		spacing: 6

		ClippingRectangle {
			anchors.horizontalCenter: parent.horizontalCenter
			width: 120
			height: 120
			radius: width / 2
			color: Config.high
			border.width: 3
			border.color: Config.primary

			Image {
				id: avatar
				anchors.fill: parent
				source: LockConfig.avatar ? Wallpaper.fileUrl(LockConfig.avatar) : ""
				sourceSize: Qt.size(240, 240)
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
			}

			Icon {
				anchors.centerIn: parent
				visible: avatar.status !== Image.Ready
				name: "person"
				size: 64
				filled: true
				color: Config.dim
				// Qt's default renderer garbles a filled Material Symbol this big
				renderType: Text.NativeRendering
			}
		}

		Item { width: 1; height: 8 }

		Text {
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			elide: Text.ElideRight
			text: LockConfig.shownName
			color: Config.text
			font.family: Config.font
			font.pixelSize: Config.title
			font.weight: Font.DemiBold
		}

		Text {
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			elide: Text.ElideRight
			text: LockConfig.shownInfo
			color: Config.dim
			font.family: Config.font
			font.pixelSize: Config.body
		}

		Item { width: 1; height: 14 }

		SearchBar {
			id: passwordBox
			width: parent.width

			icon: "lock"
			placeholder: "Password"
			focus: true
			enabled: !root.context.unlockInProgress
			field.echoMode: TextInput.Password
			field.inputMethodHints: Qt.ImhSensitiveData
			transform: Translate { id: nudge }

			// Update the text in the context when the text in the box changes.
			onTextChanged: root.context.currentText = text;

			// Try to unlock when enter is pressed.
			onAccepted: root.context.tryUnlock();
			onEscaped: root.context.currentText = "";

			Pill {
				icon: "arrow_forward"
				kind: "filled"

				// don't steal focus from the text box
				activeFocusOnTab: false

				enabled: root.context.currentText !== ""
				onClicked: root.context.tryUnlock();
			}
		}

		// always takes its place, so the column doesn't jump when it shows
		Text {
			width: parent.width
			topPadding: 8
			horizontalAlignment: Text.AlignHCenter
			text: root.context.unlockInProgress ? "Checking…" : "Incorrect password"
			opacity: root.context.unlockInProgress || root.context.showFailure ? 1 : 0
			color: root.context.unlockInProgress ? Config.dim : Config.bad
			font.family: Config.font
			font.pixelSize: Config.body
			font.weight: Font.Medium
		}
	}

	// the wrong password: the field shakes its head
	SequentialAnimation {
		id: shake
		NumberAnimation { target: nudge; property: "x"; to: -12; duration: 50 }
		NumberAnimation { target: nudge; property: "x"; to: 10; duration: 70 }
		NumberAnimation { target: nudge; property: "x"; to: -6; duration: 60 }
		NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
	}

	Connections {
		target: LockConfig

		function onImageChanged() {
			background.broken = "";
		}
	}

	Connections {
		target: root.context

		// Update the text in the box to match the text in the context.
		// This makes sure multiple monitors have the same text.
		function onCurrentTextChanged() {
			passwordBox.text = root.context.currentText;
		}

		function onShowFailureChanged() {
			if (root.context.showFailure) shake.restart();
		}
	}
}
