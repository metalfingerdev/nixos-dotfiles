// AudioIsland.qml

import QtQuick
import qs.services

Item {
    property int targetWidth:  420
    property int targetHeight: 220

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 32
            text: Volume.muted ? "Muted" : Volume.percent + "%"
        }

        Rectangle {
            id: track
            width: 280; height: 8; radius: 4
            color: "#3a3540"
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: track.width * Volume.volume
                height: track.height
                radius: 4
                color: "#8a7fff"
            }

            MouseArea {
                anchors.fill: parent
                onPressed:         (m) => Volume.setVolume(m.x / track.width)
                onPositionChanged: (m) => { if (pressed) Volume.setVolume(m.x / track.width) }
            }
        }
    }
}