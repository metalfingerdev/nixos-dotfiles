import QtQuick
import qs.modules.components
import qs.modules.services

Row {
    id: root

    property real dot: 8
    property real bar: 28
    property bool clickable: false

    spacing: 6

    Repeater {
        model: Desktops.shown

        Rectangle {
            id: pip
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: wsId === Desktops.activeId
            readonly property bool used: Desktops.occupied(wsId)

            anchors.verticalCenter: parent.verticalCenter
            width: active ? root.bar : root.dot
            height: root.dot
            radius: height / 2
            color: active ? Config.primary : used ? Config.text : Config.outline
            opacity: active || used ? 1 : 0.7
            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }

            MouseArea {
                anchors { fill: parent; margins: -4 }
                enabled: root.clickable
                cursorShape: Qt.PointingHandCursor
                onClicked: Desktops.focus(pip.wsId)
            }
        }
    }
}
