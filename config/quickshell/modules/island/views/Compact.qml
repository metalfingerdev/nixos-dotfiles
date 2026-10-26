import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The resting view: the clock. While something plays, the album cover (or bouncing bars when
// there is no cover) sits left of it; while charging, a bolt sits right of it. The island grows
// to fit, so it's a capsule of whatever is there.
// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    id: root

    readonly property bool media: Players.active !== null && (Players.active.trackTitle ?? "") !== ""
    readonly property bool charging: Energy.charging

    implicitWidth: Math.max(120, row.implicitWidth + 28)
    implicitHeight: 36

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // the cover, or the bars when the player has none
        ClippingRectangle {
            visible: root.media
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 6
            color: Config.raised

            Image {
                id: cover
                anchors.fill: parent
                source: Players.active?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
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
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH : mm")
            color: Config.text
            font.family: Config.font
            font.pixelSize: Config.body
            font.weight: Font.DemiBold
        }

        // bars beside a cover too, so "playing" reads at a glance
        Equalizer {
            visible: root.media && Players.playing && cover.status === Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            running: Players.playing
            barWidth: 2
            height: 12
            color: Config.accent
        }

        Icon {
            visible: root.charging
            anchors.verticalCenter: parent.verticalCenter
            name: "bolt"
            size: 16
            filled: true
            color: Config.good
        }
    }
}
