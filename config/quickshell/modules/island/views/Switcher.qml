import QtQuick
import qs.modules.parts

// A capsule as tall as the clock, so the island only stretches sideways.
Item {
    implicitWidth: dots.implicitWidth + 40
    implicitHeight: 36

    WorkspaceDots {
        id: dots
        anchors.centerIn: parent
        clickable: true
    }
}
