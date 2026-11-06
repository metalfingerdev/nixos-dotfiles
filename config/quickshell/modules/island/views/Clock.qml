import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components

Item {
    id: root

    readonly property int pad: 24

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // the month on show, as an offset from the current one
    property int shift: 0
    readonly property date shown: new Date(clock.date.getFullYear(), clock.date.getMonth() + shift, 1)
    readonly property int week: {
        const d = new Date(Date.UTC(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate()))
        const day = d.getUTCDay() || 7
        d.setUTCDate(d.getUTCDate() + 4 - day)
        return Math.ceil(((d - new Date(Date.UTC(d.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7)
    }

    implicitWidth: 780
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 16

        Header {
            width: parent.width
            title: "Calendar"
            onBack: Engine.back()

            Pill { visible: root.shift !== 0; implicitHeight: 48; kind: "text"; text: "Today"; shortcut: "t"; onClicked: root.shift = 0 }
            Pill { icon: "chevron_left";  implicitHeight: 48; iconSize: 24; shortcut: "["; onClicked: root.shift-- }
            Pill { icon: "chevron_right"; implicitHeight: 48; iconSize: 24; shortcut: "]"; onClicked: root.shift++ }
        }

        Row {
            width: parent.width
            spacing: 24

            Column {
                width: parent.width - card.width - parent.spacing
                anchors.verticalCenter: card.verticalCenter
                spacing: 8

                Row {
                    spacing: 8

                    Label {
                        id: time
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        font.pixelSize: 88
                        font.weight: Font.Light
                        font.features: { "tnum": 1 }
                    }
                    Label {
                        anchors.baseline: time.baseline
                        text: Qt.formatDateTime(clock.date, "ss")
                        color: Config.primary
                        font.pixelSize: Config.headline
                        font.features: { "tnum": 1 }
                    }
                }
                Label {
                    text: Qt.formatDateTime(clock.date, "dddd")
                    font.pixelSize: Config.title
                }
                Label {
                    text: Qt.formatDateTime(clock.date, "d MMMM yyyy") + "  ·  week " + root.week
                    color: Config.dim
                    font.pixelSize: Config.large
                }
            }

            Rectangle {
                id: card
                width: month.implicitWidth + 32
                height: month.implicitHeight + 32
                radius: Config.cardRadius
                color: Config.container

                Column {
                    id: month
                    x: 16; y: 16
                    spacing: 8

                    Label {
                        leftPadding: 8
                        text: Qt.formatDateTime(root.shown, "MMMM yyyy")
                        font.pixelSize: Config.large
                        font.weight: Font.Medium
                    }
                    CalendarGrid {
                        cell: 44
                        year: root.shown.getFullYear()
                        month: root.shown.getMonth()
                        today: clock.date
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["[ ]", "month"], ["T", "today"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
