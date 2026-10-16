import QtQuick
import qs.modules.taskbar

// Placeholder: what pinning Idle opens.
Item {
    implicitWidth: 520
    implicitHeight: 260

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Dashboard (placeholder)"
            color: "#f7f7f7"
            font.pixelSize: 20
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Pill { text: "media"; onClicked: IslandState.send(IslandState.Event.Open, IslandState.View.Media) }
            Pill { text: "back";  onClicked: IslandState.send(IslandState.Event.Back) }
        }
    }
}