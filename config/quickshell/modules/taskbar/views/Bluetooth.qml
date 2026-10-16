import QtQuick
import QtQuick.Layouts
import qs.modules.taskbar
import qs.modules.services

// Pinned view. implicitWidth/Height tell the island how big to morph.
Item {
    id: root

    implicitWidth:  320
    implicitHeight: headerH + listH + footerH

    readonly property int rowH:    44
    readonly property int headerH: 48
    readonly property int footerH: 44
    readonly property int listH:   Math.min(BlueZ.devices.length, 5) * rowH + emptyH
    readonly property int emptyH:  BlueZ.devices.length === 0 && BlueZ.powered ? rowH : 0

    // ── header ────────────────────────────────────────────────────────────────
    Item {
        id: header
        width: root.width
        height: root.headerH

        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth"
            color: "#f7f7f7"
            font.pixelSize: 15
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Pill {
                text: BlueZ.powered ? "on" : "off"
                onClicked: BlueZ.togglePower()
            }
            Pill {
                text: "back"
                onClicked: IslandState.send(IslandState.Event.Back)
            }
        }
    }

    // ── device list ───────────────────────────────────────────────────────────
    Column {
        y: root.headerH
        width: root.width

        // no adapter
        Item {
            width: root.width
            height: !BlueZ.available ? root.rowH : 0
            visible: !BlueZ.available
            Text {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                text: "No adapter found"
                color: "#ff6b6b"
                font.pixelSize: 13
            }
        }

        // powered off
        Item {
            width: root.width
            height: BlueZ.available && !BlueZ.powered ? root.rowH : 0
            visible: BlueZ.available && !BlueZ.powered
            Text {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth is off"
                color: "#9a9a9a"
                font.pixelSize: 13
            }
        }

        // empty + powered
        Item {
            width: root.width
            height: root.emptyH
            visible: root.emptyH > 0
            Text {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                text: BlueZ.isScanning ? "Scanning…" : "No devices found"
                color: "#9a9a9a"
                font.pixelSize: 13
            }
        }

        Repeater {
            model: BlueZ.devices

            delegate: Item {
                required property var modelData
                width: root.width
                height: root.rowH

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    color: modelData.connected ? "#1e3a2f" : (rowArea.containsMouse ? "#1e1e1e" : "transparent")
                }

                Row {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.connected ? "󰂱" : "󰂯"
                        color: modelData.connected ? "#4ade80" : "#9a9a9a"
                        font.pixelSize: 16
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name || modelData.address
                        color: "#f7f7f7"
                        font.pixelSize: 13
                        width: root.width - 16 - 28 - 12 - 80
                        elide: Text.ElideRight
                    }
                }

                Pill {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.connected ? "disconnect" : "connect"
                    onClicked: modelData.connected
                        ? modelData.disconnectDevice()
                        : modelData.connectDevice()
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }

    // ── footer ────────────────────────────────────────────────────────────────
    Item {
        y: root.headerH + root.listH
        width: root.width
        height: root.footerH
        visible: BlueZ.powered

        Rectangle {
            anchors.top: parent.top
            width: parent.width - 32
            x: 16
            height: 1
            color: "#2a2a2a"
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Pill {
                text: BlueZ.isScanning ? "stop scan" : "scan"
                onClicked: BlueZ.toggleScan()
            }
        }
    }
}