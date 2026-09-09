// Power.qml
// qs/bar/buttons/

import QtQuick
import qs.services

Rectangle {
    id: button

    property real screenW: 0

    implicitHeight: 32
    implicitWidth:  label.implicitWidth + 16

    radius: 8
    color:  "#27232b"

    Text {
        id: label
        anchors.centerIn: parent
        color: Battery.critical ? "#ff6b6b"
             : Battery.charging ? "#a8e6a3"
             :                  "white"
        text: Battery.charging ? "󰂄 " + Battery.percent + "%"
            : Battery.percent > 80 ? "󰁹 " + Battery.percent + "%"
            : Battery.percent > 60 ? "󰁿 " + Battery.percent + "%"
            : Battery.percent > 40 ? "󰁼 " + Battery.percent + "%"
            : Battery.percent > 20 ? "󰁺 " + Battery.percent + "%"
            :                      "󰂎 " + Battery.percent + "%"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            var pos = button.mapToGlobal(button.width / 2, button.height / 2)
            BarState.changeView("power", "island", pos.x, button.screenW)
        }
    }
}