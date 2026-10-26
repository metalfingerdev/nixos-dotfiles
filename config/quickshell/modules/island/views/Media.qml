import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Now playing (the active MPRIS player), wide, with the album art blurred behind it:
//   big art on the left; the player, title and artist; the position (click, drag, or focus it and
//   use Left/Right to seek); shuffle · previous · play/pause · next · repeat
//   Output: where the sound goes (click another device to move it there)
//   Players: the others, when there are several (click one to show and control it)
// Keys: P play/pause, B previous, N next, S shuffle, R repeat, arrows/Tab move, Backspace back, Escape closes.
// Also the toast Triggers raises when a track starts.
Item {
    id: root

    readonly property var player: Players.active
    readonly property bool hasLength: Players.length > 0
    readonly property int pad: 24

    function clock(seconds) {
        if (!(seconds >= 0)) return "-:--"
        const s = Math.floor(seconds), m = Math.floor(s / 60)
        return (m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") : m) + ":" + String(s % 60).padStart(2, "0")
    }

    Component.onCompleted: Players.watch(true)
    Component.onDestruction: Players.watch(false)

    implicitWidth: player ? 780 : 520
    implicitHeight: (player ? column.implicitHeight : empty.implicitHeight) + 2 * pad

    // ---- the art, blurred, fading into the island ----
    Item {
        visible: root.player !== null && backdrop.status === Image.Ready
        width: parent.width
        height: Math.min(parent.height, 320)

        Image {
            id: backdrop
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(192, 192)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: backdrop
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.2
            opacity: 0.5
        }
    }

    // ---- nothing playing ----
    Column {
        id: empty
        visible: !root.player
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 16

        Header {
            width: parent.width
            title: "Media"
            subtitle: "Nothing is playing"
            onBack: Engine.back()
        }
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "music_off"
            size: 48
            color: Config.outline
        }
    }

    // ---- a player ----
    Column {
        id: column
        visible: root.player !== null
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 18

        Header {
            width: parent.width
            title: "Now playing"
            subtitle: (root.player?.identity ?? "") + "  ·  " + Audio.label(Audio.sink)
            onBack: Engine.back()

            Equalizer {
                count: 5
                barWidth: 4
                height: 20
                running: Players.playing
                color: Config.primary
            }
        }

        Row {
            width: parent.width
            spacing: 24

            ClippingRectangle {
                id: art
                width: 240
                height: 240
                radius: Config.cardRadius + 4
                color: Config.container

                Icon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    name: "music_note"
                    size: 64
                    color: Config.outline
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(480, 480)
                }
            }

            Item {
                width: parent.width - art.width - parent.spacing
                height: art.height

                Column {
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
                    spacing: 4

                    Text {
                        width: parent.width
                        text: root.player?.trackTitle || "Unknown title"
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.headline
                        font.weight: Font.DemiBold
                    }
                    Text {
                        width: parent.width
                        text: root.player?.trackArtist || root.player?.trackAlbum || ""
                        elide: Text.ElideRight
                        color: Config.dim
                        font.family: Config.font
                        font.pixelSize: Config.large + 1
                    }
                }

                // position, then the controls, at the foot of the column
                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: 14

                    Item {
                        visible: root.hasLength
                        width: parent.width
                        height: 20

                        Text {
                            id: elapsed
                            anchors.verticalCenter: parent.verticalCenter
                            width: 52
                            // while dragging: where the drop would seek to
                            text: root.clock(seekBar.dragging ? seekBar.shownFraction * Players.length : Players.position)
                            color: Config.dim
                            font.family: Config.font
                            font.pixelSize: Config.body
                            font.features: { "tnum": 1 }
                        }
                        Progress {
                            id: seekBar
                            anchors { left: elapsed.right; right: total.left; verticalCenter: parent.verticalCenter }
                            thickness: 6
                            fraction: root.hasLength ? Players.position / Players.length : 0
                            seekable: Players.canSeek
                            onSeek: f => Players.seek(f)
                        }
                        Text {
                            id: total
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: 52
                            horizontalAlignment: Text.AlignRight
                            text: root.clock(Players.length)
                            color: Config.dim
                            font.family: Config.font
                            font.pixelSize: Config.body
                            font.features: { "tnum": 1 }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 76

                        Pill {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            kind: "text"
                            icon: "shuffle"
                            iconSize: 24
                            implicitHeight: 52
                            active: Players.shuffle
                            shortcut: "s"
                            enabled: root.player?.shuffleSupported ?? false
                            onClicked: Players.toggleShuffle()
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 16

                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "skip_previous"
                                iconSize: 30
                                implicitHeight: 64
                                shortcut: "b"
                                enabled: root.player?.canGoPrevious ?? false
                                onClicked: Players.previous()
                            }
                            // the play button: a rounded square while playing (Material 3's expressive FAB)
                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                kind: "filled"
                                icon: Players.playing ? "pause" : "play_arrow"
                                iconSize: 36
                                implicitHeight: 76
                                implicitWidth: 96
                                radius: Players.playing ? 24 : 38
                                shortcut: "p"
                                focus: true                    // Enter/Space toggle playback straight away
                                enabled: Players.canToggle
                                onClicked: Players.toggle()
                                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }
                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "skip_next"
                                iconSize: 30
                                implicitHeight: 64
                                shortcut: "n"
                                enabled: root.player?.canGoNext ?? false
                                onClicked: Players.next()
                            }
                        }

                        Pill {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            kind: "text"
                            icon: Players.loop === "track" ? "repeat_one" : "repeat"
                            iconSize: 24
                            implicitHeight: 52
                            active: Players.loop !== "none"
                            shortcut: "r"
                            enabled: root.player?.loopSupported ?? false
                            onClicked: Players.cycleLoop()
                        }
                    }
                }
            }
        }

        // ---- where it plays, and the other players ----
        Row {
            width: parent.width
            spacing: 20

            Column {
                visible: Audio.sinks.length > 0
                width: Players.list.length > 1 ? (parent.width - parent.spacing) / 2 : parent.width
                spacing: 6

                Text {
                    leftPadding: 4
                    bottomPadding: 4
                    text: "Output"
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.large
                    font.weight: Font.Medium
                }
                Repeater {
                    model: Audio.sinks.slice(0, 4)

                    ListEntry {
                        required property var modelData
                        width: parent.width
                        icon: Audio.glyph(modelData)
                        title: Audio.label(modelData)
                        active: modelData === Audio.sink
                        onClicked: Audio.setSink(modelData)
                    }
                }
            }

            Column {
                visible: Players.list.length > 1
                width: (parent.width - parent.spacing) / 2
                spacing: 6

                Text {
                    leftPadding: 4
                    bottomPadding: 4
                    text: "Players"
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.large
                    font.weight: Font.Medium
                }
                Repeater {
                    model: Players.list

                    ListEntry {
                        id: entry
                        required property var modelData
                        width: parent.width
                        title: modelData.trackTitle || modelData.identity
                        subtitle: (modelData.trackArtist ? modelData.trackArtist + "  ·  " : "") + modelData.identity
                        active: modelData === Players.active
                        lead: Component {
                            ClippingRectangle {
                                width: 44; height: 44; radius: 12
                                color: Config.high
                                Image {
                                    anchors.fill: parent
                                    source: entry.modelData.trackArtUrl ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize: Qt.size(88, 88)
                                }
                            }
                        }
                        onClicked: Players.picked = modelData
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Space", "play / pause"], ["← →", "seek, on the bar"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
