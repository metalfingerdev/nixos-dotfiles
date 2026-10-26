import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// How everything looks (also `open settings`). Each choice applies at once and is remembered
// (components/Config.qml; the wallpaper by awww itself).
//   palette    each card previews its own colours
//   island     shape (floating / notch), auto-hide handle (strip / none), glass and its opacity
//   wallpaper  the folder's images (services/Wallpaper.qml): click or Enter applies, R = random
Item {
    id: root

    readonly property int columns: 4
    readonly property int tileW: 104
    readonly property int tileH: 76
    readonly property int thumbW: 132
    readonly property int thumbH: 80

    implicitWidth: columns * tileW + (columns - 1) * 8 + 32
    implicitHeight: column.implicitHeight + 32

    component Label: Text {
        leftPadding: 4
        color: Config.primary
        font.family: Config.font
        font.pixelSize: Config.body
        font.weight: Font.DemiBold
    }

    Column {
        id: column
        x: 16; y: 16
        width: parent.width - 32
        spacing: 12

        Header {
            width: parent.width
            title: "Theme"
            subtitle: Config.current.label + (Wallpaper.current ? "  ·  " + Wallpaper.baseName(Wallpaper.current) : "")
            onBack: Engine.back()
        }

        // ---- palette ----
        Label { text: "Colours" }

        Grid {
            columns: root.columns
            spacing: 8

            Repeater {
                model: Config.names

                Tile {
                    id: tile
                    required property string modelData
                    readonly property var p: Config.palettes[modelData]

                    width: root.tileW
                    height: root.tileH
                    padding: 10
                    tint: p.surface
                    current: Config.name === modelData
                    focus: current                       // the keyboard starts on the palette in use
                    onClicked: Config.name = modelData

                    Text {
                        anchors { left: parent.left; top: parent.top }
                        text: tile.p.label
                        color: tile.p.text
                        font.family: Config.font
                        font.pixelSize: Config.body
                        font.weight: Font.DemiBold
                    }

                    // primary, secondary, container: the colours the island is made of
                    Row {
                        anchors { left: parent.left; bottom: parent.bottom }
                        spacing: -6

                        Repeater {
                            model: [tile.p.primary, tile.p.secondary, tile.p.container]

                            Rectangle {
                                required property string modelData
                                width: 22
                                height: 22
                                radius: 11
                                color: modelData
                                border.width: 2
                                border.color: tile.p.surface
                            }
                        }
                    }

                    Icon {
                        visible: tile.current
                        anchors { right: parent.right; bottom: parent.bottom }
                        name: "check_circle"
                        size: 20
                        filled: true
                        color: tile.p.primary
                    }
                }
            }
        }

        // ---- the island ----
        Label { text: "Island"; topPadding: 4 }

        Row {
            width: parent.width
            spacing: 8

            Segmented {
                width: (parent.width - 8) / 2
                options: [{ key: "pill", label: "Floating" }, { key: "notch", label: "Notch" }]
                current: Config.style
                onPicked: key => Config.style = key
            }
            Segmented {
                width: (parent.width - 8) / 2
                options: [{ key: "strip", label: "Handle" }, { key: "none", label: "No handle" }]
                current: Config.handle
                onPicked: key => Config.handle = key
            }
        }

        Item {
            width: parent.width
            height: 32

            Text {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: "Frosted glass"
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.body + 1
            }
            Toggle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked: Config.glass
                onToggled: on => Config.glass = on
            }
        }

        // opacity: 20 % .. 100 %
        Slider {
            visible: Config.glass
            width: parent.width
            implicitHeight: 40
            icon: "opacity"
            value: (Config.glassOpacity - 0.2) / 0.8
            valueText: Math.round(Config.glassOpacity * 100) + "%"
            onMoved: v => Config.glassOpacity = 0.2 + v * 0.8
        }

        // ---- wallpaper ----
        Item {
            width: parent.width
            height: 36

            Label {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Wallpaper"
            }
            Pill {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: Wallpaper.files.length > 1
                icon: "shuffle"
                text: "Random"
                onClicked: Wallpaper.random()
            }
        }

        Text {
            visible: Wallpaper.files.length === 0
            leftPadding: 4
            text: "No images in " + Wallpaper.dir
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        ListView {
            id: strip

            visible: Wallpaper.files.length > 0
            width: parent.width
            height: root.thumbH
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpaper.files
            highlightMoveDuration: 150
            currentIndex: Math.max(0, Wallpaper.currentIndex)
            Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Center)

            // the list takes its keys itself, so ViewLoader never sees them: report them here
            Keys.onPressed: event => {
                Engine.key()
                if (event.key === Qt.Key_R) { Wallpaper.random(); event.accepted = true }
                else event.accepted = false
            }
            Keys.onLeftPressed:   decrementCurrentIndex()
            Keys.onRightPressed:  incrementCurrentIndex()
            Keys.onReturnPressed: Wallpaper.set(Wallpaper.files[currentIndex])
            Keys.onEnterPressed:  Wallpaper.set(Wallpaper.files[currentIndex])
            activeFocusOnTab: true

            // the wheel scrolls sideways
            WheelHandler {
                onWheel: e => {
                    const d = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x
                    strip.contentX = Math.max(0, Math.min(Math.max(0, strip.contentWidth - strip.width), strip.contentX - d))
                }
            }

            delegate: ClippingRectangle {
                id: thumb
                required property string modelData
                required property int index
                readonly property bool applied: modelData === Wallpaper.current

                width: root.thumbW
                height: root.thumbH
                radius: Config.innerRadius
                color: Config.container

                Image {
                    anchors.fill: parent
                    source: Wallpaper.fileUrl(thumb.modelData)
                    sourceSize: Qt.size(root.thumbW * 2, root.thumbH * 2)   // decode small: wallpapers are big
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // applied: a primary ring and a check; keyboard: a plain ring
                Rectangle {
                    anchors.fill: parent
                    radius: thumb.radius
                    color: "transparent"
                    border.width: thumb.applied || (strip.activeFocus && thumb.ListView.isCurrentItem) ? 3 : 0
                    border.color: thumb.applied ? Config.primary : Config.text
                }
                Rectangle {
                    visible: thumb.applied
                    anchors { right: parent.right; top: parent.top; margins: 6 }
                    width: 22; height: 22; radius: 11
                    color: Config.primary

                    Icon {
                        anchors.centerIn: parent
                        name: "check"
                        size: 16
                        color: Config.primaryInk
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { strip.currentIndex = thumb.index; Wallpaper.set(thumb.modelData) }
                }
            }
        }
    }
}
