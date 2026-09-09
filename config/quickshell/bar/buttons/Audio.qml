// Audio.qml

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
    anchors.centerIn: parent
    text: Volume.muted ? "muted" : Volume.percent + "%"
    color: "white"
  }

  MouseArea {
      anchors.fill: parent
      onClicked: {
          var pos = button.mapToGlobal(button.width / 2, button.height / 2)
          BarState.changeView("audio", "island", pos.x, button.screenW)
      }
  }
}