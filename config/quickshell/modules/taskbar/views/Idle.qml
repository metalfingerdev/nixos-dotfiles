import QtQuick
import Quickshell
import qs.modules.taskbar

// Resting view: shown on hover (Peek) and when clicked (Pinned).
Item {
    implicitWidth: 1080
    implicitHeight: 72

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#f7f7f7"
            font.pixelSize: 22
        }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "workspaces"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Workspaces)
        }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "launcher"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Launcher)
        } 

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "dashboard"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Dashboard)
        }    

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "media"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Media)
        }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "notify"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Notify)
        }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            text: "theme"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Theme)
        }

        Pill {
            text: "bluetooth"
            onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Bluetooth)
        }
    }
}