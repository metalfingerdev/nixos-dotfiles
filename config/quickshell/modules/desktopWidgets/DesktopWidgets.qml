// qs/widgets/DesktopWidgets.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root

    property bool showPowerMenu: false

    function ordinal(n) {
        if (n >= 11 && n <= 13)
            return "th";

        switch (n % 10) {
        case 1:
            return "st";
        case 2:
            return "nd";
        case 3:
            return "rd";
        default:
            return "th";
        }
    }

    WlrLayershell.namespace: "quickshell:widgets"
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: false // sits below normal windows, like eww's :stacking "bg"
    implicitWidth: 340
    implicitHeight: 220

    anchors {
        bottom: true
        right: true
    }

    margins {
        bottom: 50
        right: 50
    }

    SystemClock {
        id: clock

        precision: SystemClock.Hours
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // ── Icon row (swaps to power menu) ──────────────────
        Rectangle {
            Layout.preferredWidth: 340
            Layout.preferredHeight: 100
            color: Config.background
            border.color: "#d8cab8"
            border.width: 0
            radius: 12

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.showPowerMenu ? [{
                        "icon": "",
                        "cmd": ["systemctl", "poweroff"],
                        "hover": "#fc4649",
                        "active": "#862526",
                        "size": 40
                    }, {
                        "icon": "",
                        "cmd": ["systemctl", "suspend"],
                        "hover": "#7b91fc",
                        "active": "#515ea1",
                        "size": 42
                    }, {
                        "icon": "",
                        "close": true,
                        "hover": "#ac82e9",
                        "active": "#634a88",
                        "size": 48
                    }] : [{
                        "icon": "⌘",
                        "cmd": ["sh", "-c", "kitty --directory \"$HOME\""],
                        "hover": "#ac82e9",
                        "active": "#634a88",
                        "size": 50
                    }, {
                        "icon": "",
                        "cmd": ["sh", "-c", "thunar"],
                        "hover": "#ac82e9",
                        "active": "#634a88",
                        "size": 45
                    }, {
                        "icon": "",
                        "openMenu": true,
                        "hover": "#ac82e9",
                        "active": "#634a88",
                        "size": 45
                    }]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 10
                        radius: 6
                        color: iconMouse.pressed ? modelData.active : iconMouse.containsMouse ? modelData.hover : Config.highlight

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
                                if (modelData.openMenu)
                                    root.showPowerMenu = true;
                                else if (modelData.close)
                                    root.showPowerMenu = false;
                                else
                                    Quickshell.execDetached(modelData.cmd);
                            }
                        }

                    }

                }

            }

        }

        // ── Date pills ───────────────────────────────────────
        RowLayout {
            spacing: 20

            Repeater {
                model: [clock.date.getDate() + ordinal(clock.date.getDate()), Qt.formatDateTime(clock.date, "MMM"), Qt.formatDateTime(clock.date, "yyyy")]

                delegate: Rectangle {
                    width: 100
                    height: 100
                    color: Config.background
                    border.color: "#d8cab8"
                    border.width: 0
                    radius: 12

                    // Changed from Layout to anchors
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 10
                        radius: 6
                        color: Config.highlight

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 24
                            font.bold: true
                            font.family: "Maple Mono"
                            color: "#d8cab8"
                        }

                    }

                }

            }

        }

    }

}