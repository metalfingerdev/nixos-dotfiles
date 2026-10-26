import QtQuick
import QtQuick.Layouts
import qs.modules.island
import qs.modules.components

// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    implicitWidth: 480
    implicitHeight: 36

    RowLayout {
        anchors.centerIn: parent
        spacing: 8

        Pill {
            text: "Network"
            onClicked: x => Engine.open(Engine.View.Network, x)
        }

        Pill {
            text: "Launcher"
            onClicked: x => Engine.open(Engine.View.Launcher, x)
        }

        Pill {
            text: "Bluetooth"
            onClicked: x => Engine.open(Engine.View.Bluetooth, x)
        }

        Pill {
            text: "Notifications"
            onClicked: x => Engine.open(Engine.View.Notifications, x)
        }
    }
}