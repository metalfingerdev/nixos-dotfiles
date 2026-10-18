import QtQuick
import Quickshell
import qs.modules.taskbar
import qs.modules.services

// Always-on resting view. Clock/date, plus bars while music plays.
Item {
    // The island morphs to this, so it grows when the bars appear.
    implicitWidth: Math.max(120, row.implicitWidth + 32)
    implicitHeight: IslandState.compactHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        CavaBars {
            anchors.verticalCenter: parent.verticalCenter
            visible: Player.playing        // invisible items don't count toward implicitWidth
            running: Player.playing
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: "#f7f7f7"
            font.pixelSize: 13
            text: IslandState.compactWidget === IslandState.Widget.Date
                  ? Qt.formatDateTime(clock.date, "ddd d MMM")
                  : Qt.formatDateTime(clock.date, "HH:mm")
        }
    }
}