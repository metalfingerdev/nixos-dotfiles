import QtQuick

// Always six weeks, so the height never changes between months.
Item {
    id: root

    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    property date today: new Date()
    // 0 = Sunday ... 6 = Saturday, like Date.getDay() (Locale says 1 = Monday ... 7 = Sunday)
    property int firstDay: Qt.locale().firstDayOfWeek % 7
    property int cell: 30

    readonly property int offset: (new Date(year, month, 1).getDay() - firstDay + 7) % 7

    implicitWidth: cell * 7
    implicitHeight: cell * 7

    function dayAt(i) { return new Date(year, month, 1 - offset + i) }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    Grid {
        columns: 7

        Repeater {
            model: 7

            Label {
                required property int index
                width: root.cell
                height: root.cell
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.NarrowFormat)
                color: Config.dim
                font.pixelSize: Config.small
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: 42

            Item {
                id: day
                required property int index
                readonly property date date: root.dayAt(index)
                readonly property bool inMonth: date.getMonth() === root.month
                readonly property bool isToday: root.sameDay(date, root.today)

                width: root.cell
                height: root.cell

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cell - 4
                    height: width
                    radius: width / 2
                    visible: day.isToday
                    color: Config.primary
                }

                Label {
                    anchors.centerIn: parent
                    text: day.date.getDate()
                    color: day.isToday ? Config.primaryInk : day.inMonth ? Config.text : Config.outline
                    opacity: day.inMonth ? 1 : 0.6
                    font.weight: day.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
