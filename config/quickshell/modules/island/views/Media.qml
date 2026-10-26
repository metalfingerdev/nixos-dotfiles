import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Now playing (the active MPRIS player), with the album art blurred across the top:
//   art, title, artist and the player; bars while it plays
//   the position (click or drag to seek) between elapsed and total
//   shuffle · previous · play/pause · next · repeat (off -> track -> playlist)
//   Output: where the sound goes (click another device to move it there)
//   Players: the others, when there are several (click one to show and control it)
// Also the toast Triggers raises when a track starts. Escape goes back.
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

    implicitWidth: 460
    implicitHeight: (player ? column.implicitHeight : empty.implicitHeight) + 40

    // ---- the art, blurred, fading into the island ----
    Item {
        visible: root.player !== null && backdrop.status === Image.Ready
        width: parent.width
        height: Math.min(parent.height, 280)

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
            blurMax: 56
            saturation: 0.2
            opacity: 0.5
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0.2) }
                GradientStop { position: 1.0; color: Config.surface }
            }
        }
    }

    // ---- nothing playing ----
    Column {
        id: empty
        visible: !root.player
        x: 20; y: 20
        width: parent.width - 40
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
            size: 40
            color: Config.outline
        }
    }

    // ---- a player ----
    Column {
        id: column
        visible: root.player !== null
        x: 20; y: 20
        width: parent.width - 40
        spacing: 18

        Item {
            width: parent.width
            height: art.height

            ClippingRectangle {
                id: art
                width: 104
                height: 104
                radius: Config.innerRadius
                color: Config.container

                Icon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    name: "music_note"
                    size: 40
                    color: Config.outline
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(208, 208)
                }
            }

            Column {
                anchors { left: art.right; leftMargin: 16; right: bars.left; rightMargin: 10; verticalCenter: art.verticalCenter }
                spacing: 3

                Text {
                    width: parent.width
                    text: root.player?.trackTitle || "Unknown title"
                    elide: Text.ElideRight
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.title + 2
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: root.player?.trackArtist || root.player?.trackAlbum || ""
                    elide: Text.ElideRight
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.large
                }
                Row {
                    spacing: 6
                    topPadding: 2

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "graphic_eq"
                        size: 15
                        color: Config.primary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.player?.identity ?? ""
                        color: Config.dim
                        font.family: Config.font
                        font.pixelSize: Config.small + 1
                    }
                }
            }

            Equalizer {
                id: bars
                anchors { right: parent.right; top: parent.top; topMargin: 8 }
                count: 5
                barWidth: 3
                height: 18
                running: Players.playing
                color: Config.primary
            }
        }

        // ---- position ----
        Item {
            visible: root.hasLength
            width: parent.width
            height: 18

            Text {
                id: elapsed
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                // while dragging: where the drop would seek to
                text: root.clock(seekBar.dragging ? seekBar.shownFraction * Players.length : Players.position)
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.small + 1
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
                width: 44
                horizontalAlignment: Text.AlignRight
                text: root.clock(Players.length)
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.small + 1
                font.features: { "tnum": 1 }
            }
        }

        // ---- controls ----
        Item {
            width: parent.width
            height: 64

            Pill {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                kind: "text"
                icon: "shuffle"
                iconSize: 22
                implicitHeight: 44
                active: Players.shuffle
                enabled: root.player?.shuffleSupported ?? false
                onClicked: Players.toggleShuffle()
            }

            Row {
                anchors.centerIn: parent
                spacing: 14

                Pill {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_previous"
                    iconSize: 26
                    implicitHeight: 52
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: Players.previous()
                }
                // the play button: a rounded square, not a circle (Material 3's "expressive" FAB)
                Pill {
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "filled"
                    icon: Players.playing ? "pause" : "play_arrow"
                    iconSize: 32
                    implicitHeight: 64
                    implicitWidth: 76
                    radius: Players.playing ? 20 : 32
                    focus: true                    // Enter/Space toggle playback straight away
                    enabled: Players.canToggle
                    onClicked: Players.toggle()
                    Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                Pill {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_next"
                    iconSize: 26
                    implicitHeight: 52
                    enabled: root.player?.canGoNext ?? false
                    onClicked: Players.next()
                }
            }

            Pill {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                kind: "text"
                icon: Players.loop === "track" ? "repeat_one" : "repeat"
                iconSize: 22
                implicitHeight: 44
                active: Players.loop !== "none"
                enabled: root.player?.loopSupported ?? false
                onClicked: Players.cycleLoop()
            }
        }

        // ---- where it plays ----
        Column {
            visible: Audio.sinks.length > 0
            width: parent.width
            spacing: 4

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
                    implicitHeight: 52
                    icon: Audio.glyph(modelData)
                    title: Audio.label(modelData)
                    active: modelData === Audio.sink
                    onClicked: Audio.setSink(modelData)
                }
            }
        }

        // ---- the other players ----
        Column {
            visible: Players.list.length > 1
            width: parent.width
            spacing: 4

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
                            width: 40; height: 40; radius: 10
                            color: Config.high
                            Image {
                                anchors.fill: parent
                                source: entry.modelData.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(80, 80)
                            }
                        }
                    }
                    onClicked: Players.picked = modelData
                }
            }
        }
    }
}
