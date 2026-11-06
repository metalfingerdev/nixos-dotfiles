import QtQuick
import qs.modules.parts

Item {
    implicitWidth: 440
    implicitHeight: 72

    VolumeSlider {
        anchors { fill: parent; margins: 10 }
        activeFocusOnTab: false
    }
}
