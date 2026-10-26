import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.island
import qs.modules.components

// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    implicitWidth: 120
    implicitHeight: 36

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: Qt.formatDateTime(clock.date, "HH : mm")
            color: "#f7f7f7"
            font.pixelSize: 13
        }
    }
}