import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The island grows to fit, so it's a capsule of whatever is there.
Item {
    id: root

    implicitWidth: Math.max(120, row.implicitWidth + 32)
    implicitHeight: 36

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Row {
            visible: Toggles.recording
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: Config.recording
                SequentialAnimation on opacity {
                    running: Toggles.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Toggles.recordTime
                color: Config.recording
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }

        ClippingRectangle {
            visible: Players.hasTrack
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 11
            color: Config.container

            CoverImage {
                id: cover
                source: Players.active?.trackArtUrl ?? ""
                sourceSize: Qt.size(44, 44)
                visible: status === Image.Ready
                opacity: Players.playing ? 1 : 0.5
            }
            Equalizer {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                running: Players.playing
                barWidth: 2
                height: 12
                color: Config.primary
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        // bars beside a cover too, so "playing" reads at a glance
        Equalizer {
            visible: Players.hasTrack && Players.playing && cover.status === Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            running: Players.playing
            barWidth: 2
            height: 12
            color: Config.primary
        }

        Icon {
            visible: Notifier.dnd
            anchors.verticalCenter: parent.verticalCenter
            name: "do_not_disturb_on"
            size: 16
            filled: true
            color: Config.dim
        }

        Icon {
            visible: Energy.charging
            anchors.verticalCenter: parent.verticalCenter
            name: "bolt"
            size: 16
            filled: true
            color: Config.good
        }
    }
}
