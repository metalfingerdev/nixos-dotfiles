import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// How everything looks. Each choice applies at once and is remembered (components/Config.qml;
// the wallpaper by awww itself).
//   palette    each tile previews its own colours
//   island     shape (pill / notch), auto-hide handle (strip / none), glass and its opacity
//   wallpaper  the folder's images (services/Wallpaper.qml): click or Enter applies, R = random
Item {
    id: root

    readonly property int columns: 3
    readonly property int tileW: 122
    readonly property int tileH: 66
    readonly property int thumbW: 120
    readonly property int thumbH: 72

    implicitWidth: columns * tileW + (columns - 1) * 8 + 24
    implicitHeight: column.implicitHeight + 24

    component Label: Text {
        color: Config.dim
        font.family: Config.font
        font.pixelSize: Config.small
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
    }

    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 10

        Header {
            width: parent.width
            icon: "palette"
            title: "Theme"
            subtitle: Config.current.label + (Wallpaper.current ? "  ·  " + Wallpaper.baseName(Wallpaper.current) : "")
            onBack: Engine.back()
        }

        // ---- palette ----
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

                    Row {
                        anchors { left: parent.left; bottom: parent.bottom }
                        spacing: 4

                        Repeater {
                            model: [tile.p.raised, tile.p.dim, tile.p.text, tile.p.accent, tile.p.good, tile.p.bad]

                            Rectangle {
                                required property string modelData
                                width: 14
                                height: 14
                                radius: 7
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(0.5, 0.5, 0.5, 0.35)
                            }
                        }
                    }
                }
            }
        }

        // ---- the island ----
        Label { text: "Island" }

        Row {
            spacing: 6

            Pill { text: "pill";  active: Config.style === "pill";  onClicked: Config.style = "pill" }
            Pill { text: "notch"; active: Config.style === "notch"; onClicked: Config.style = "notch" }
            Item { width: 10; height: 1 }
            Pill { text: "strip handle"; active: Config.handle === "strip"; onClicked: Config.handle = "strip" }
            Pill { text: "no handle"; active: Config.handle === "none"; onClicked: Config.handle = "none" }
        }

        Item {
            width: parent.width
            height: 28

            Row {
                id: glassRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Config.glass
                    onToggled: on => Config.glass = on
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Frosted glass"
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.body
                }
            }

            // opacity: 20 % .. 100 %
            Progress {
                anchors { left: glassRow.right; leftMargin: 14; right: amount.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                visible: Config.glass
                fraction: (Config.glassOpacity - 0.2) / 0.8
                color: Config.accent
                seekable: true
                onSeek: f => Config.glassOpacity = 0.2 + f * 0.8
            }
            Text {
                id: amount
                visible: Config.glass
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: Math.round(Config.glassOpacity * 100) + "%"
                color: Config.dim
                font.family: Config.mono
                font.pixelSize: Config.small
            }
        }

        // ---- wallpaper ----
        Item {
            width: parent.width
            height: 24

            Label {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Wallpaper"
            }
            Pill {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: Wallpaper.files.length > 1
                icon: "shuffle"
                text: "random"
                onClicked: Wallpaper.random()
            }
        }

        Text {
            visible: Wallpaper.files.length === 0
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
                radius: Config.innerRadius + 2
                color: Config.raised
                border.width: applied ? 2 : (strip.activeFocus && ListView.isCurrentItem ? 1 : 0)
                border.color: applied ? Config.accent : Config.text

                Image {
                    anchors.fill: parent
                    source: Wallpaper.fileUrl(thumb.modelData)
                    sourceSize: Qt.size(root.thumbW * 2, root.thumbH * 2)   // decode small: wallpapers are big
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
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
