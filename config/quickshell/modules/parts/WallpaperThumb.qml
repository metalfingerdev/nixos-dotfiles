import QtQuick
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

// One wallpaper as a rounded thumbnail (views/Theme.qml's row, views/Wallpapers.qml's grid). The
// one showing has a primary ring and a check; `picked` (the keyboard's selection in its list) a
// thick ring. Under the pointer, its file name shows along the bottom. A click emits clicked():
// the view applies it.
ClippingRectangle {
    id: root

    property string path: ""
    property bool picked: false
    readonly property bool applied: path !== "" && path === Wallpaper.current
    readonly property bool ringed: picked && Config.focusVisible
    signal clicked()

    radius: Config.innerRadius
    color: Config.container

    Image {
        anchors.fill: parent
        source: root.path ? Wallpaper.fileUrl(root.path) : ""
        sourceSize: Qt.size(384, 240)            // decode small: wallpapers are big
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // the file name, under the pointer
    Rectangle {
        visible: area.containsMouse
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 34
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0) }
            GradientStop { position: 1; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0.85) }
        }

        Text {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 7 }
            text: Wallpaper.baseName(root.path)
            elide: Text.ElideMiddle
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.small
        }
    }

    // applied: a primary ring and a check; the keyboard's pick: a thick ring
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.ringed ? 4 : root.applied ? 3 : 0
        border.color: root.applied && !root.ringed ? Config.primary : Config.text
    }
    Rectangle {
        visible: root.applied
        anchors { right: parent.right; top: parent.top; margins: 8 }
        width: 24; height: 24; radius: 12
        color: Config.primary

        Icon {
            anchors.centerIn: parent
            name: "check"
            size: 16
            color: Config.primaryInk
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
