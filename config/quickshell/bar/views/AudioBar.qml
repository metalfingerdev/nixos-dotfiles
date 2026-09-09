// AudioBar.qml

import QtQuick
import qs.services

Item {
    property int targetWidth:  420
    property int targetHeight: 48

    Row {
        anchors.centerIn: parent
        spacing: 8
        Text {
            color: "white"
            text: Volume.muted ? "Muted" : Volume.percent + "%"
        }
    }
}