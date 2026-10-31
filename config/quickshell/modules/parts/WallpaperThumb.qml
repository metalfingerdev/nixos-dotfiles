import QtQuick
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

ClippingRectangle {
    id: root

    property string path: ""
    property bool picked: false
    readonly property bool applied: path !== "" && path === Wallpaper.current
    readonly property bool ringed: picked && Config.focusVisible
    signal clicked()

    radius: Config.innerRadius
    color: Config.container

    CoverImage {
        source: root.path ? Wallpaper.fileUrl(root.path) : ""
        sourceSize: Qt.size(384, 240)            // decode small: wallpapers are big
    }

    Rectangle {
        visible: area.containsMouse
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 34
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0) }
            GradientStop { position: 1; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0.85) }
        }

        Label {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 7 }
            text: Wallpaper.baseName(root.path)
            elide: Text.ElideMiddle
            font.pixelSize: Config.small
        }
    }

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

    ClickArea {
        id: area
        onClicked: root.clicked()
    }
}
