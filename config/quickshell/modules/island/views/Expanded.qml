import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// What the clock grows into while the pointer is on the island (Machine's Peek phase), after the
// Dynamic Island: the time and date, what's on (each segment opens its view, the group around them
// the dashboard) and what's playing, with its controls. It has no keyboard and lives only as long as
// the hover, so the pointer passing over it can't take typing from an app. A click anywhere else on
// it opens Tabs (Bar.pinShown).
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property int pad: 12
    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""

    implicitWidth: 460 + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 8

        Item {
            width: parent.width
            height: 52

            Column {
                id: when
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: -1

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.title + 2
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "ddd d MMM")
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: Config.small
                }
            }

            StatusGroup {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                maxWidth: parent.width - when.x - when.width - 16
                onClicked: (view, x) => Engine.open(view, x)
            }
        }

        MediaCard {
            visible: root.media
            width: parent.width
            compact: true
        }
    }
}
