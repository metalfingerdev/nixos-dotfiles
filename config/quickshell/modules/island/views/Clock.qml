import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components

// The time with seconds, the date, and a month calendar (‹ › change month, "today" returns).
Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // the month on show, as an offset from the current one
    property int shift: 0
    readonly property date shown: new Date(clock.date.getFullYear(), clock.date.getMonth() + shift, 1)

    implicitWidth: 300
    implicitHeight: column.implicitHeight + 24

    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 10

        Item {
            width: parent.width
            height: time.implicitHeight

            Row {
                anchors.left: parent.left
                spacing: 4

                Text {
                    id: time
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.display
                    font.weight: Font.Light
                }
                Text {
                    anchors.baseline: time.baseline
                    text: Qt.formatDateTime(clock.date, "ss")
                    color: Config.faint
                    font.family: Config.mono
                    font.pixelSize: Config.large
                }
            }

            Pill {
                anchors { right: parent.right; top: parent.top }
                text: "back"
                onClicked: Engine.back()
            }
        }

        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        Rectangle { width: parent.width; height: 1; color: Config.track }

        Item {
            width: parent.width
            height: 28

            Text {
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: Qt.formatDateTime(root.shown, "MMMM yyyy")
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.body
                font.weight: Font.DemiBold
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6

                Pill { visible: root.shift !== 0; text: "today"; onClicked: root.shift = 0 }
                Pill { icon: "chevron_left";  onClicked: root.shift-- }
                Pill { icon: "chevron_right"; onClicked: root.shift++ }
            }
        }

        CalendarGrid {
            anchors.horizontalCenter: parent.horizontalCenter
            cell: 36
            year: root.shown.getFullYear()
            month: root.shown.getMonth()
            today: clock.date
        }
    }
}
