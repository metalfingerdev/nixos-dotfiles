import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// It has no keyboard and lives only as long as the hover, so the pointer passing over it can't take
// typing from an app.
Item {
    id: root

    readonly property int pad: 12

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

            DateStamp {
                id: when
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                date: clock.date
            }

            StatusGroup {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                maxWidth: parent.width - when.x - when.width - 16
                onClicked: (view, x) => Engine.open(view, x)
            }
        }

        MediaCard {
            visible: Players.hasTrack
            width: parent.width
            compact: true
        }
    }
}
