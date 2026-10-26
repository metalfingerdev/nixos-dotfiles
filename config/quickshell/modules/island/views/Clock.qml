import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components

// The time with seconds, the date, and a month calendar in a card (‹ › change month, "Today" returns).
Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // the month on show, as an offset from the current one
    property int shift: 0
    readonly property date shown: new Date(clock.date.getFullYear(), clock.date.getMonth() + shift, 1)

    implicitWidth: 340
    implicitHeight: column.implicitHeight + 32

    Column {
        id: column
        x: 16; y: 16
        width: parent.width - 32
        spacing: 14

        Item {
            width: parent.width
            height: time.implicitHeight

            Row {
                anchors.left: parent.left
                leftPadding: 4
                spacing: 6

                Text {
                    id: time
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.display + 8
                    font.weight: Font.Light
                    font.features: { "tnum": 1 }
                }
                Text {
                    anchors.baseline: time.baseline
                    text: Qt.formatDateTime(clock.date, "ss")
                    color: Config.primary
                    font.family: Config.font
                    font.pixelSize: Config.title
                    font.features: { "tnum": 1 }
                }
            }

            Pill {
                anchors { right: parent.right; top: parent.top; topMargin: 6 }
                kind: "text"
                icon: "arrow_back"
                iconSize: 22
                implicitHeight: 40
                activeFocusOnTab: false
                onClicked: Engine.back()
            }
        }

        Text {
            leftPadding: 4
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.large
        }

        Rectangle {
            width: parent.width
            height: month.implicitHeight + 24
            radius: Config.cardRadius
            color: Config.container

            Column {
                id: month
                x: 12; y: 12
                width: parent.width - 24
                spacing: 6

                Item {
                    width: parent.width
                    height: 36

                    Text {
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        text: Qt.formatDateTime(root.shown, "MMMM yyyy")
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.large
                        font.weight: Font.Medium
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 2

                        Pill { visible: root.shift !== 0; kind: "text"; text: "Today"; onClicked: root.shift = 0 }
                        Pill { kind: "text"; icon: "chevron_left";  iconSize: 22; onClicked: root.shift-- }
                        Pill { kind: "text"; icon: "chevron_right"; iconSize: 22; onClicked: root.shift++ }
                    }
                }

                CalendarGrid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    cell: 40
                    year: root.shown.getFullYear()
                    month: root.shown.getMonth()
                    today: clock.date
                }
            }
        }
    }
}
