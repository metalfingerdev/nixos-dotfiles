// Workspaces.qml

import QtQuick
import qs.services

Row {
    id: container

    property real screenW: 0

    property var workspaces: [1, 2, 3]

    spacing: 4

    Repeater {
        model: container.workspaces

        Rectangle {
            id: button

            implicitHeight: 32
            implicitWidth: label.implicitWidth + 16

            radius: 8
            color: "#27232b"

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var pos = button.mapToGlobal(button.width / 2, button.height / 2)
                    BarState.changeView("workspaces", "island", pos.x, container.screenW)
                }
            }
        }
    }
}