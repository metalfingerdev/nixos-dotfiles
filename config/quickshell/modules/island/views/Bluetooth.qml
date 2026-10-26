import QtQuick
import QtQuick.Layouts
import qs.modules.island
import qs.modules.components

// Placeholder body: real content needs a service (see docs/roadmap.md). The contract is already met.
Item {
    implicitWidth: 520
    implicitHeight: 160

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bluetooth"
            color: "#f7f7f7"
            font.pixelSize: 20
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bluetooth details are not connected to a data source yet"
            color: "#8a8a92"
            font.pixelSize: 12
        }

        Pill {
            Layout.alignment: Qt.AlignHCenter
            text: "Back"
            onClicked: Engine.back()
        }
    }
}