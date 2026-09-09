// BrightnessBar.qml
// Place in: qs/bar/views/

import QtQuick
import qs.services

Item {
    property int targetWidth:  360
    property int targetHeight: 48

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            color: "white"
            font.pixelSize: 16
            text: "󰃟"
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: track
            width: 260; height: 8; radius: 4; color: "#3a3540"
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: track.width * (Brightness.percent / 100)
                height: parent.height; radius: 4
                color: "#f0c060"

                Behavior on width {
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            color: "white"
            font.pixelSize: 13
            text: Brightness.percent + "%"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}