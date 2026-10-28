import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The volume mixer: every level in one place.
//   Output      the default output (the slider's icon mutes it)
//   Microphone  the default microphone, when there is one
//   Apps        one slider per app playing sound (a stream each, so a browser's tabs are apart),
//               with its icon, its name and what it plays; the rest scroll
//   the media button (M): what's playing, and where it plays
// Keys: Tab/arrows move between sliders, Left/Right set the focused one, Enter/Space mute it,
// Backspace back, Escape closes.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property int pad: 24
    readonly property int maxRows: 4          // apps shown at once; the rest scroll
    readonly property int rowH: 66            // an app: its name over a slider
    readonly property int rowGap: 14

    function glyph(level, muted) {
        return muted ? "volume_off" : level < 34 ? "volume_mute" : level < 67 ? "volume_down" : "volume_up"
    }

    implicitWidth: 640
    implicitHeight: column.implicitHeight + 2 * pad

    // a section's title, and a dim detail beside it (the device)
    component Label: Item {
        property string title: ""
        property string detail: ""
        width: parent.width
        height: heading.implicitHeight + 4

        Text {
            id: heading
            x: 4
            text: parent.title
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.large
            font.weight: Font.Medium
        }
        Text {
            anchors { left: heading.right; leftMargin: 10; right: parent.right; baseline: heading.baseline }
            visible: text !== ""
            text: parent.detail
            elide: Text.ElideRight
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 14

        Header {
            width: parent.width
            title: "Mixer"
            subtitle: Audio.streams.length === 0 ? "No app is playing sound"
                    : Audio.streams.length === 1 ? "1 app playing sound" : Audio.streams.length + " apps playing sound"
            onBack: Engine.back()

            Pill {
                kind: "text"
                icon: Config.symbol.media
                iconSize: 22
                shortcut: "m"
                onClicked: x => Engine.open(Engine.View.Media, x)
            }
        }

        // ---- the devices ----
        Label { title: "Output"; detail: Audio.label(Audio.sink) }
        Slider {
            width: parent.width
            focus: true
            enabled: Audio.sink !== null
            icon: root.glyph(Audio.volume, Audio.muted)
            value: Audio.muted ? 0 : Audio.volume / 100
            valueText: Audio.muted ? "Muted" : Audio.volume + "%"
            iconClickable: true
            onMoved: v => Audio.setVolume(v * 100)
            onIconClicked: Audio.toggleMute()
        }

        Label { visible: Audio.hasMic; title: "Microphone"; detail: Audio.label(Audio.source) }
        Slider {
            visible: Audio.hasMic
            width: parent.width
            icon: Audio.micMuted ? "mic_off" : "mic"
            value: Audio.micMuted ? 0 : Audio.micVolume / 100
            valueText: Audio.micMuted ? "Muted" : Audio.micVolume + "%"
            iconClickable: true
            onMoved: v => Audio.setLevel(Audio.source, v * 100)
            onIconClicked: Audio.toggleMic()
        }

        // ---- the apps ----
        Label { title: "Apps" }
        Text {
            visible: Audio.streams.length === 0
            width: parent.width
            topPadding: 4
            bottomPadding: 8
            horizontalAlignment: Text.AlignHCenter
            text: "Nothing is playing sound right now"
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        // out by its inset, so the rows line up with the sliders above
        ScrollList {
            id: list
            visible: Audio.streams.length > 0
            x: -inset
            width: parent.width + 2 * inset
            spacing: root.rowGap
            maxHeight: root.maxRows * (root.rowH + root.rowGap) - root.rowGap + 2 * inset

            Repeater {
                model: Audio.streams

                Item {
                    id: app
                    required property var modelData
                    readonly property int level: Audio.level(modelData)
                    readonly property bool silent: Audio.isMuted(modelData)
                    readonly property string iconPath: Audio.appIcon(modelData)

                    width: list.innerWidth
                    height: root.rowH

                    // the app's own icon, or a note in a tonal circle
                    Item {
                        id: lead
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44

                        IconImage {
                            visible: app.iconPath !== ""
                            anchors.centerIn: parent
                            implicitSize: 40
                            asynchronous: true
                            source: app.iconPath
                        }
                        Rectangle {
                            visible: app.iconPath === ""
                            anchors.fill: parent
                            radius: 22
                            color: Config.high

                            Icon {
                                anchors.centerIn: parent
                                name: Config.symbol.media
                                size: 22
                                color: Config.text
                            }
                        }
                    }

                    Column {
                        id: info
                        anchors { left: lead.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 6

                        // the app, then what it plays
                        Item {
                            width: parent.width
                            height: name.implicitHeight

                            Text {
                                id: name
                                x: 2
                                width: Math.min(implicitWidth, parent.width - 2)
                                text: Audio.appName(app.modelData)
                                elide: Text.ElideRight
                                color: Config.text
                                font.family: Config.font
                                font.pixelSize: Config.body + 1
                                font.weight: Font.Medium
                            }
                            Text {
                                anchors { left: name.right; leftMargin: 8; right: parent.right; baseline: name.baseline }
                                visible: text !== ""
                                text: Audio.mediaName(app.modelData)
                                elide: Text.ElideRight
                                color: Config.dim
                                font.family: Config.font
                                font.pixelSize: Config.small + 1
                            }
                        }

                        Slider {
                            width: parent.width
                            implicitHeight: 40
                            icon: root.glyph(app.level, app.silent)
                            value: app.silent ? 0 : app.level / 100
                            valueText: app.silent ? "Muted" : app.level + "%"
                            iconClickable: true
                            onMoved: v => Audio.setLevel(app.modelData, v * 100)
                            onIconClicked: Audio.toggleMuted(app.modelData)
                        }
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "volume, on a slider"], ["Space", "mute"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
