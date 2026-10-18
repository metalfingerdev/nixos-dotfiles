import QtQuick
import Quickshell.Widgets
import qs.modules.taskbar
import qs.modules.services

// Pinned view: a scrollable strip of thumbnails. Click / Enter applies, R = random,
// Left/Right to move, Esc to close.
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

    readonly property int cellW: 160
    readonly property int cellH: 96
    readonly property int headerH: 40
    readonly property bool empty: Wallpaper.files.length === 0

    implicitWidth: 560
    implicitHeight: headerH + (empty ? 40 : cellH + 20) + 4


    // ---- header ----
    Item {
        width: root.width
        height: root.headerH

        Text {
            x: 16
            width: root.width - 180
            anchors.verticalCenter: parent.verticalCenter
            text: Wallpaper.current !== "" ? Wallpaper.baseName(Wallpaper.current) : "Wallpaper"
            elide: Text.ElideMiddle
            color: "#f7f7f7"
            font.pixelSize: 13
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Pill { text: "random"; onClicked: Wallpaper.random() }
            Pill { text: "back";  onClicked: IslandState.send(IslandState.openHome()) }
        }
    }

    // ---- thumbnails ----
    ListView {
        id: list

        x: 12
        y: root.headerH
        width: root.width - 24
        height: root.cellH + 8
        visible: !root.empty

        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Wallpaper.files

        function sync() {
            currentIndex = Math.max(0, Wallpaper.currentIndex)
            positionViewAtIndex(currentIndex, ListView.Center)
        }
        Component.onCompleted: sync()
        Connections { target: Wallpaper; function onFilesChanged() { list.sync() } }
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        Keys.onLeftPressed:   decrementCurrentIndex()
        Keys.onRightPressed:  incrementCurrentIndex()
        Keys.onReturnPressed: Wallpaper.set(Wallpaper.files[currentIndex])
        Keys.onEnterPressed:  Wallpaper.set(Wallpaper.files[currentIndex])
        Keys.onEscapePressed: IslandState.send(IslandState.Event.Escape)
        Keys.onPressed: e => { if (e.key === Qt.Key_R) Wallpaper.random() }

        // scroll wheel -> horizontal
        WheelHandler {
            onWheel: e => {
                const d = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x
                list.contentX = Math.max(0, Math.min(Math.max(0, list.contentWidth - list.width),
                                                     list.contentX - d))
            }
        }

        delegate: ClippingRectangle {
            id: cell

            required property string modelData
            required property int index
            readonly property bool applied: modelData === Wallpaper.current

            width: root.cellW
            height: root.cellH
            radius: 12
            color: "#1a1a1a"
            border.width: applied ? 2 : (ListView.isCurrentItem ? 1 : 0)
            border.color: applied ? "#C4E881" : "#f7f7f7"

            Image {
                anchors.fill: parent
                source: Wallpaper.fileUrl(cell.modelData)
                sourceSize.width: 320          // decode small: keeps memory sane with big wallpapers
                sourceSize.height: 192
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    list.currentIndex = cell.index
                    Wallpaper.set(cell.modelData)
                }
            }
        }
    }

    Text {
        visible: root.empty
        x: 16; y: root.headerH + 10
        text: "No images in " + Wallpaper.dir
        color: "#9a9a9a"
        font.pixelSize: 13
    }
}