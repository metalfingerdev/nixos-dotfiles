import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

ClippingRectangle {
    id: root

    property bool compact: false
    readonly property var player: Players.active
    readonly property bool hasLength: Players.length > 0

    Component.onCompleted: Players.watch(true)
    Component.onDestruction: Players.watch(false)

    implicitWidth: 420
    implicitHeight: compact ? 84 : 164
    radius: Config.cardRadius
    color: Config.container

    // the scrim keeps the text readable over the art
    CoverImage {
        id: backdrop
        source: root.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(192, 192)
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: backdrop
        visible: backdrop.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 40
        saturation: 0.15
        opacity: 0.7
    }
    Rectangle {
        anchors.fill: parent
        visible: backdrop.status === Image.Ready
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(Config.container.r, Config.container.g, Config.container.b, 0.88) }
            GradientStop { position: 1.0; color: Qt.rgba(Config.container.r, Config.container.g, Config.container.b, 0.45) }
        }
    }

    Item {
        visible: root.compact
        anchors.fill: parent

        ClippingRectangle {
            id: thumb
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            height: 56
            radius: Config.smallRadius
            color: Config.high

            CoverImage {
                id: thumbArt
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(96, 96)
            }
            Equalizer {
                anchors.centerIn: parent
                visible: thumbArt.status !== Image.Ready
                running: Players.playing
                color: Config.primary
            }
        }

        Column {
            anchors { left: thumb.right; leftMargin: 12; right: compactControls.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2

            Label {
                width: parent.width
                text: root.player?.trackTitle || "Unknown title"
                elide: Text.ElideRight
                font.pixelSize: Config.body + 1
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                text: root.player?.trackArtist || root.player?.identity || ""
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
        }
        MouseArea {
            anchors { left: parent.left; right: compactControls.left; top: parent.top; bottom: parent.bottom }
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => Engine.open(Engine.View.Media, mapToItem(null, mouse.x, mouse.y).x)
        }

        Row {
            id: compactControls
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 2

            Pill { kind: "text"; icon: "skip_previous"; iconSize: 22; enabled: root.player?.canGoPrevious ?? false; onClicked: Players.previous() }
            Pill {
                implicitHeight: 48
                kind: "filled"
                icon: Players.playing ? "pause" : "play_arrow"
                iconSize: 22
                enabled: Players.canToggle
                onClicked: Players.toggle()
            }
            Pill { kind: "text"; icon: "skip_next"; iconSize: 22; enabled: root.player?.canGoNext ?? false; onClicked: Players.next() }
        }

        Progress {
            visible: root.hasLength
            anchors { left: thumb.right; leftMargin: 12; right: compactControls.left; rightMargin: 8; bottom: parent.bottom; bottomMargin: 9 }
            thickness: 3
            fraction: root.hasLength ? Players.position / Players.length : 0
        }
    }

    Item {
        visible: !root.compact
        anchors { fill: parent; margins: 16 }

        Row {
            id: output
            spacing: 6
            width: parent.width - play.width - 12

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Audio.glyph(Audio.sink)
                size: 15
                color: Config.dim
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 21
                text: (root.player?.identity ?? "") + "  ·  " + Audio.label(Audio.sink)
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
        }

        Column {
            id: words
            anchors { left: parent.left; right: play.left; rightMargin: 12; top: output.bottom; topMargin: 12 }
            spacing: 2

            Label {
                width: parent.width
                text: root.player?.trackTitle || "Unknown title"
                elide: Text.ElideRight
                font.pixelSize: Config.title
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                text: root.player?.trackArtist || root.player?.trackAlbum || ""
                elide: Text.ElideRight
                color: Config.dim
            }
        }
        MouseArea {
            anchors.fill: words
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => Engine.open(Engine.View.Media, mapToItem(null, mouse.x, mouse.y).x)
        }

        Pill {
            id: play
            anchors { right: parent.right; verticalCenter: words.verticalCenter; verticalCenterOffset: -6 }
            implicitHeight: 64
            kind: "filled"
            icon: Players.playing ? "pause" : "play_arrow"
            iconSize: 30
            enabled: Players.canToggle
            onClicked: Players.toggle()
        }

        Row {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            spacing: 6

            Pill {
                id: prev
                kind: "text"
                icon: "skip_previous"
                iconSize: 24
                implicitHeight: 40
                enabled: root.player?.canGoPrevious ?? false
                onClicked: Players.previous()
            }
            Progress {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - prev.width - next.width - 12
                thickness: 4
                fraction: root.hasLength ? Players.position / Players.length : 0
                seekable: Players.canSeek
                onSeek: f => Players.seek(f)
            }
            Pill {
                id: next
                kind: "text"
                icon: "skip_next"
                iconSize: 24
                implicitHeight: 40
                enabled: root.player?.canGoNext ?? false
                onClicked: Players.next()
            }
        }
    }
}
