import QtQuick
import qs.modules.taskbar
import qs.modules.services

FocusScope {
    id: root

    Component.onCompleted: root.forceActiveFocus()
    onVisibleChanged: {
        if (visible) root.forceActiveFocus()
    }

    property bool keyboardActive: false
    readonly property bool engaged: keyboardActive

    Keys.onPressed: (event) => {
        keyboardActive = true
            if (event.key === Qt.Key_Backspace ) {
                IslandState.send(IslandState.Event.Back)
                event.accepted = true
            } else {
                event.accepted = false
            }
    }
    
    implicitWidth: 380
    implicitHeight: 110

    Row {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Album Art or fallback icon container
        Rectangle {
            width: 78
            height: 78
            radius: 12
            color: "#222222"
            clip: true

            Image {
                anchors.fill: parent
                source: Player.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: source != ""
            }

            Text {
                anchors.centerIn: parent
                text: "🎵"
                font.pixelSize: 24
                visible: !parent.children[0].visible
            }
        }

        // Track info and controls column
        Column {
            width: 250
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            // Track Title & Artist
            Column {
                width: parent.width
                spacing: 2

                Text {
                    width: parent.width
                    text: Player.active ? (Player.title !== "" ? Player.title : "Unknown Track") : "No media playing"
                    color: "#f7f7f7"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: Player.active ? (Player.artist !== "" ? Player.artist : "Unknown Artist") : "Waiting for player..."
                    color: "#aaaaaa"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // Media Control Buttons Row
            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Pill {
                    text: "⏮"
                    enabled: Player.player?.canGoPrevious ?? false
                    onClicked: Player.previous()
                }

                Pill {
                    text: Player.playing ? "⏸" : "▶"
                    enabled: Player.player?.canTogglePlaying ?? false
                    onClicked: Player.toggle()
                }

                Pill {
                    text: "⏭"
                    enabled: Player.player?.canGoNext ?? false
                    onClicked: Player.next()
                }

                Pill {
                    text: "↩"
                    onClicked: IslandState.send(IslandState.openHome())
                }
            }
        }
    }
}