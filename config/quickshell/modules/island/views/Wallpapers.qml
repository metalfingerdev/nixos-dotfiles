import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The wallpapers (views/Theme.qml shows them in one row; this is all of them):
//   the one showing, big (its name is in the header)
//   every image in Wallpaper.dir, four across; more scroll. A click applies one (awww remembers it)
// Its colours are views/Colours.qml's (from the wallpaper).
// Named Wallpapers, not Wallpaper: a view must not share a singleton's name (services/Wallpaper.qml).
// Keys: R random, arrows/Tab move (in the grid the arrows pick and Enter/Space apply; off its edge
// they leave it), Backspace back, Escape closes.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 840
    readonly property int across: 4
    readonly property int rows: 2               // shown at once; the rest scroll
    readonly property real gap: 12
    readonly property bool any: Wallpaper.files.length > 0

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 16

        Header {
            width: parent.width
            title: "Wallpaper"
            subtitle: (Wallpaper.current ? Wallpaper.baseName(Wallpaper.current) + "  ·  " : "")
                    + Wallpaper.files.length + (Wallpaper.files.length === 1 ? " image" : " images")
            onBack: Engine.back()

            Pill {
                visible: Wallpaper.files.length > 1
                icon: "shuffle"
                text: "Random"
                shortcut: "r"
                onClicked: Wallpaper.random()
            }
        }

        // ---- the one showing ----
        ClippingRectangle {
            visible: Wallpaper.current !== ""
            width: parent.width
            height: 200
            radius: Config.cardRadius
            color: Config.container

            Image {
                anchors.fill: parent
                source: Wallpaper.current ? Wallpaper.fileUrl(Wallpaper.current) : ""
                sourceSize: Qt.size(1280, 720)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // ---- every image ----
        Item {
            visible: root.any
            width: parent.width
            height: grid.height

            GridView {
                id: grid

                // each cell carries half a gap on every side: hang those outside the column so the
                // thumbnails line up with its edges
                x: -root.gap / 2
                width: parent.width + root.gap
                height: Math.max(1, Math.min(root.rows, Math.ceil(count / root.across))) * cellHeight
                cellWidth: width / root.across
                cellHeight: Math.round((cellWidth - root.gap) * 0.625) + root.gap
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Wallpaper.files
                currentIndex: Math.max(0, Wallpaper.currentIndex)
                focus: true                              // the keyboard starts here
                activeFocusOnTab: true
                Component.onCompleted: positionViewAtIndex(currentIndex, GridView.Contain)

                // the grid moves its own selection with the arrows (off its edge it lets them go,
                // and ViewLoader moves focus out); report every key, so the countdown restarts
                Keys.onPressed: event => { Engine.key(); event.accepted = false }
                Keys.onReturnPressed: Wallpaper.set(Wallpaper.files[currentIndex])
                Keys.onEnterPressed:  Wallpaper.set(Wallpaper.files[currentIndex])
                Keys.onSpacePressed:  Wallpaper.set(Wallpaper.files[currentIndex])

                delegate: Item {
                    id: cell
                    required property string modelData
                    required property int index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    WallpaperThumb {
                        anchors { fill: parent; margins: root.gap / 2 }
                        path: cell.modelData
                        picked: grid.activeFocus && cell.GridView.isCurrentItem
                        onClicked: { grid.currentIndex = cell.index; Wallpaper.set(cell.modelData) }
                    }
                }
            }
        }

        // ---- nothing to show ----
        Column {
            visible: !root.any
            width: parent.width
            topPadding: 24
            bottomPadding: 24
            spacing: 10

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Config.symbol.wallpaper
                size: 48
                color: Config.dim
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No images in " + Wallpaper.dir
                color: Config.dim
                font.family: Config.font
                font.pixelSize: Config.body
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "pick"], ["↵", "apply"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
