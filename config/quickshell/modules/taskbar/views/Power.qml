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

    implicitWidth: 480
    implicitHeight: 120

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

                RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: [{
                        "icon": "\uf011",
                        "cmd": ["systemctl", "poweroff"],
                        "hover": "#fc4649",
                        "active": "#862526",
                        "size": 40
                    }, {
                        "icon": "\uead2",
                        "cmd": ["systemctl", "reboot"],
                        "hover": "#ac82e9",
                        "active": "#634a88",
                        "size": 44

                    }, {
                        "icon": "\uf186",
                        "cmd": ["systemctl", "suspend"],
                        "hover": "#7b91fc",
                        "active": "#515ea1",
                        "size": 44
                    }, {
                        "icon": "\uf08b",
                        "cmd": ["uwsm", "stop"],
                        "hover": "#ac82e9",
                        "active": "#634a88",
                        "size": 40
                    }]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 10
                        radius: 6
                        color: iconMouse.pressed ? modelData.active : iconMouse.containsMouse ? modelData.hover : "#000000"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: "Inter"
                            font.pixelSize: modelData.size
                            color: (iconMouse.containsMouse || iconMouse.pressed) ? "#141216" : "#d8cab8"
                        }

                        MouseArea {
                            id: iconMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                    Quickshell.execDetached(modelData.cmd);
                            }
                        }

                    }

                }

            }
}