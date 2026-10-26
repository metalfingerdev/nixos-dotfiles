import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The active MPRIS player: art, title, artist, position (click or drag to seek), and controls:
// shuffle, previous, play/pause, next, repeat (off -> track -> playlist). With several players,
// the switch button cycles through them. Also the toast Triggers raises when a track starts.
Item {
    id: root

    readonly property var player: Players.active
    readonly property bool hasLength: Players.length > 0

    function clock(seconds) {
        if (!(seconds >= 0)) return "-:--"
        const s = Math.floor(seconds), m = Math.floor(s / 60)
        return (m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") : m) + ":" + String(s % 60).padStart(2, "0")
    }

    Component.onCompleted: Players.watch(true)
    Component.onDestruction: Players.watch(false)

    implicitWidth: 420
    implicitHeight: player ? 124 : 64

    // ---- nothing playing ----
    Header {
        visible: !root.player
        x: 12; y: 12
        width: parent.width - 24
        icon: "music_off"
        title: "Media"
        subtitle: "Nothing is playing"
        onBack: Engine.back()
    }

    // ---- a player ----
    Item {
        visible: root.player !== null
        anchors { fill: parent; margins: 12 }

        Rectangle {
            id: art
            width: 100
            height: 100
            radius: Config.innerRadius
            color: Config.raised
            clip: true

            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                name: "music_note"
                size: 40
                color: Config.faint
            }
            Image {
                id: cover
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(200, 200)
            }
        }

        Column {
            anchors { left: art.right; leftMargin: 14; right: parent.right; top: parent.top }
            spacing: 2

            Item {
                width: parent.width
                height: 18

                Text {
                    anchors { left: parent.left; right: tools.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: root.player?.identity ?? ""
                    elide: Text.ElideRight
                    color: Config.faint
                    font.family: Config.font
                    font.pixelSize: Config.small
                }
                Row {
                    id: tools
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 6

                    Pill {
                        visible: Players.list.length > 1
                        icon: "swap_horiz"
                        onClicked: Players.pickNext()
                    }
                    Pill { text: "back"; onClicked: Engine.back() }
                }
            }

            Text {
                width: parent.width
                text: root.player?.trackTitle || "Unknown title"
                elide: Text.ElideRight
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.large
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: root.player?.trackArtist || root.player?.trackAlbum || ""
                elide: Text.ElideRight
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.body
            }
        }

        Column {
            anchors { left: art.right; leftMargin: 14; right: parent.right; bottom: parent.bottom }
            spacing: 6

            Item {
                width: parent.width
                height: 16
                visible: root.hasLength

                Text {
                    id: elapsed
                    anchors.verticalCenter: parent.verticalCenter
                    // while dragging: where the drop would seek to
                    text: root.clock(seekBar.dragging ? seekBar.shownFraction * Players.length : Players.position)
                    color: Config.dim
                    font.family: Config.mono
                    font.pixelSize: Config.small
                }
                Progress {
                    id: seekBar
                    anchors { left: elapsed.right; leftMargin: 8; right: total.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    fraction: root.hasLength ? Players.position / Players.length : 0
                    color: Config.accent
                    seekable: Players.canSeek
                    onSeek: f => Players.seek(f)
                }
                Text {
                    id: total
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: root.clock(Players.length)
                    color: Config.dim
                    font.family: Config.mono
                    font.pixelSize: Config.small
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Pill {
                    icon: "shuffle"
                    active: Players.shuffle
                    enabled: root.player?.shuffleSupported ?? false
                    onClicked: Players.toggleShuffle()
                }
                Pill {
                    icon: "skip_previous"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: Players.previous()
                }
                Pill {
                    icon: Players.playing ? "pause" : "play_arrow"
                    implicitWidth: 44
                    focus: true                    // Enter/Space toggle playback straight away
                    enabled: Players.canToggle
                    onClicked: Players.toggle()
                }
                Pill {
                    icon: "skip_next"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: Players.next()
                }
                Pill {
                    icon: Players.loop === "track" ? "repeat_one" : "repeat"
                    active: Players.loop !== "none"
                    enabled: root.player?.loopSupported ?? false
                    onClicked: Players.cycleLoop()
                }
            }
        }
    }
}
