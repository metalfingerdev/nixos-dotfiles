import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// A stream each, so a browser's tabs are apart.
Item {
    id: root

    readonly property int pad: 24
    readonly property int maxRows: 4
    readonly property int rowH: 66
    readonly property int rowGap: 14

    implicitWidth: 640
    implicitHeight: column.implicitHeight + 2 * pad

    component Heading: Item {
        property string title: ""
        property string detail: ""
        width: parent.width
        height: heading.implicitHeight + 4

        Label {
            id: heading
            x: 4
            text: parent.title
            font.pixelSize: Config.large
            font.weight: Font.Medium
        }
        Label {
            anchors { left: heading.right; leftMargin: 10; right: parent.right; baseline: heading.baseline }
            visible: text !== ""
            text: parent.detail
            elide: Text.ElideRight
            color: Config.dim
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
                onClicked: Engine.open(Engine.View.Media)
            }
        }

        Heading { title: "Output"; detail: Audio.label(Audio.sink) }
        VolumeSlider {
            width: parent.width
            focus: true
            enabled: Audio.sink !== null
        }

        Heading { visible: Audio.hasMic; title: "Microphone"; detail: Audio.label(Audio.source) }
        VolumeSlider {
            visible: Audio.hasMic
            width: parent.width
            node: Audio.source
            icon: silent ? "mic_off" : "mic"
        }

        Heading { title: "Apps" }
        Label {
            visible: Audio.streams.length === 0
            width: parent.width
            topPadding: 4
            bottomPadding: 8
            horizontalAlignment: Text.AlignHCenter
            text: "Nothing is playing sound right now"
            color: Config.dim
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
                    readonly property string iconPath: Audio.appIcon(modelData)

                    width: list.innerWidth
                    height: root.rowH

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

                        Item {
                            width: parent.width
                            height: name.implicitHeight

                            Label {
                                id: name
                                x: 2
                                width: Math.min(implicitWidth, parent.width - 2)
                                text: Audio.appName(app.modelData)
                                elide: Text.ElideRight
                                font.pixelSize: Config.body + 1
                                font.weight: Font.Medium
                            }
                            Label {
                                anchors { left: name.right; leftMargin: 8; right: parent.right; baseline: name.baseline }
                                visible: text !== ""
                                text: Audio.mediaName(app.modelData)
                                elide: Text.ElideRight
                                color: Config.dim
                                font.pixelSize: Config.small + 1
                            }
                        }

                        VolumeSlider {
                            width: parent.width
                            implicitHeight: 40
                            node: app.modelData
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
