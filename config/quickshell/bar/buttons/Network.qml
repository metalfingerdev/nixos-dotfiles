// Network.qml

import QtQuick
import qs.services

Rectangle {
  id: button

  property real screenW: 0

  implicitHeight: 32
  implicitWidth: label.implicitWidth + 16

  radius: 8
  color: "#27232b"
  
  Text {
    id: label

    // Centers the text element directly in the middle of the rectangle
    anchors.centerIn: parent

    text: "8"
    color: "white"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
        var pos = button.mapToGlobal(button.width / 2, button.height / 2)
        BarState.changeView("network", "island", pos.x, button.screenW)
    }
  }
}
