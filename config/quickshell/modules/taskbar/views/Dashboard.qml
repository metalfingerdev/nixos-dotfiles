import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.taskbar

// Placeholder: what pinning Idle opens.
FocusScope {
    id:root

    Component.onCompleted: root.forceActiveFocus()
    onVisibleChanged: {
        if (visible) root.forceActiveFocus()
    }

    implicitWidth: 520
    implicitHeight: 260

    property bool keyboardActive: false
    readonly property bool engaged: keyboardActive

    Keys.onPressed: (event) => {
        keyboardActive = true
            if (event.key === Qt.Key_Backspace ) {
                IslandState.send(IslandState.Event.Back)
                event.accepted = true
            } else {
                event.accepted = false
            }
    }

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