import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

// One screen of the lock: the picture, and out of its way in the corners and along the bottom, who
// is locked out (top left), the clock (top right) and the password field (the very bottom). What it
// shows comes from LockConfig and what's typed from the LockContext, so every screen matches.
Rectangle {
	id: root
	required property LockContext context
	// an animated background or avatar plays while this is on (Lock.qml: not while the screens are off)
	property bool animate: true
	readonly property int margin: 48

	// a shadow, not a backing: the words stay readable on a bright picture and cover none of it
	component Lifted: MultiEffect {
		shadowEnabled: true
		shadowColor: "#000000"
		shadowOpacity: 0.85
		shadowBlur: 0.5
		shadowVerticalOffset: 1
		shadowHorizontalOffset: 0
		blurMax: 24
	}

	// the plain colour shows until the picture loads, and for good if there is no picture
	color: Config.surface

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	// plays a GIF and shows a still picture alike
	AnimatedImage {
		id: background
		// the lock image, or the wallpaper if there is none or it can't be loaded (it moved, say)
		property string broken: ""
		readonly property string path: LockConfig.image !== "" && LockConfig.image !== broken ? LockConfig.image : Wallpaper.current

		anchors.fill: parent
		source: path ? Wallpaper.fileUrl(path) : ""
		fillMode: Image.PreserveAspectCrop
		asynchronous: true
		// as the avatar's below; no sourceSize, which would rescale every frame of a GIF on the CPU
		playing: root.animate && status === Image.Ready
		cache: false
		opacity: status === Image.Ready ? 1 : 0
		// not right away: a missing file errors while `source` is being set, from `path`'s own binding
		onStatusChanged: if (status === Image.Error) Qt.callLater(() => broken = LockConfig.image);

		Behavior on opacity { NumberAnimation { duration: 200 } }
	}

	Column {
		anchors {
			right: parent.right
			top: parent.top
			margins: root.margin
		}
		layer.enabled: true
		layer.effect: Lifted {}

		Text {
			anchors.right: parent.right
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
			anchors.right: parent.right
			text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
			color: Config.text
			font.family: Config.font
			font.pixelSize: Config.title
		}
	}

	Row {
		anchors {
			left: parent.left
			top: parent.top
			margins: root.margin
		}
		spacing: 28

		ClippingRectangle {
			width: 220
			height: 220
			radius: LockConfig.avatarShape === "square" ? Config.smallRadius : width / 2
			color: Config.high
			border.width: 3
			border.color: Config.primary

			// plays a GIF and shows a still picture alike
			AnimatedImage {
				id: avatar
				anchors.fill: parent
				source: LockConfig.avatar ? Wallpaper.fileUrl(LockConfig.avatar) : ""
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				// It turns itself off for a still picture and wouldn't start the next GIF: the status
				// makes this say it again after every load.
				playing: root.animate && status === Image.Ready
				cache: false                 // a long GIF would keep every frame in memory
			}

			Icon {
				anchors.centerIn: parent
				visible: avatar.status !== Image.Ready
				name: "person"
				size: 120
				filled: true
				color: Config.dim
				// Qt's default renderer garbles a filled Material Symbol this big
				renderType: Text.NativeRendering
			}
		}

		Column {
			anchors.verticalCenter: parent.verticalCenter
			spacing: 4
			layer.enabled: true
			layer.effect: Lifted {}

			Text {
				width: Math.min(implicitWidth, 480)
				elide: Text.ElideRight
				text: LockConfig.shownName
				color: Config.text
				font.family: Config.font
				font.pixelSize: Config.headline
				font.weight: Font.DemiBold
			}

			Text {
				width: Math.min(implicitWidth, 480)
				elide: Text.ElideRight
				text: LockConfig.shownInfo
				color: Config.text
				font.family: Config.font
				font.pixelSize: Config.large
			}
		}
	}

	Column {
		// Uncommenting this will make the password entry invisible except on the active monitor.
		// visible: Window.active

		anchors {
			horizontalCenter: parent.horizontalCenter
			bottom: parent.bottom
			bottomMargin: 24
		}
		width: Math.min(parent.width - 2 * root.margin, 960)
		spacing: 10

		// always takes its place, so the field doesn't jump when it shows
		Text {
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			text: root.context.unlockInProgress ? "Checking…" : "Incorrect password"
			opacity: root.context.unlockInProgress || root.context.showFailure ? 1 : 0
			color: root.context.unlockInProgress ? Config.dim : Config.bad
			font.family: Config.font
			font.pixelSize: Config.large
			font.weight: Font.Medium
		}

		SearchBar {
			id: passwordBox
			width: parent.width
			height: 76
			fieldSize: Config.title

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
				implicitHeight: 60
				iconSize: 28
				icon: "arrow_forward"
				kind: "filled"

				// don't steal focus from the text box
				activeFocusOnTab: false

				enabled: root.context.currentText !== ""
				onClicked: root.context.tryUnlock();
			}
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
