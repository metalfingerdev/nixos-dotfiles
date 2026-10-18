import QtQuick
import QtQuick.Layouts
import qs.modules.taskbar
import qs.modules.services

// Pinned view. implicitWidth/Height tell the island how big to morph.
FocusScope {
    id: root

    Component.onCompleted: root.forceActiveFocus()
    onVisibleChanged: {
        if (visible) root.forceActiveFocus()
    }

    property bool keyboardActive: false
    readonly property bool engaged: keyboardActive

    Keys.onPressed: (event) => {
        keyboardActive = true
        if (event.key === Qt.Key_Backspace) {
            IslandState.send(IslandState.Event.Back)
            event.accepted = true
        } else {
            event.accepted = false
        }
    }

    // ── sizing ────────────────────────────────────────────────────────────────
    implicitWidth:  480
    implicitHeight: headerH + stateH + listH

    readonly property int rowH:     48
    readonly property int headerH:  70
    readonly property int maxListH: 5 * rowH

    readonly property bool ready: BlueZ.available && BlueZ.powered
    readonly property int stateH: (!ready || BlueZ.devices.length === 0) ? rowH : 0
    readonly property int listH:  ready ? Math.min(list.contentHeight, maxListH) : 0

    function activate(dev) {
        if (dev.connected) dev.disconnectDevice()
        else               dev.connectDevice()
    }

    readonly property var connectedDevice: {
        if (!BlueZ.devices) return null
        for (let i = 0; i < BlueZ.devices.length; i++) {
            if (BlueZ.devices[i].connected) return BlueZ.devices[i]
        }
        return null
    }

    readonly property string subtitle: {
        if (!BlueZ.available) return "No adapter"
        if (!BlueZ.powered)   return "Off"
        if (connectedDevice)  return connectedDevice.name || connectedDevice.address
        return "Not connected"
    }

    // small round icon button used in the header
    component IconButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool spinning: false
        signal clicked()

        width: 32; height: 32; radius: 16
        color: btnArea.containsMouse ? "#2a2a2a" : "#1e1e1e"

        onSpinningChanged: if (!spinning) glyphText.rotation = 0

        Text {
            id: glyphText
            anchors.centerIn: parent
            text: btn.glyph
            color: "#f7f7f7"
            font.pixelSize: 15

            NumberAnimation on rotation {
                from: 0; to: 360
                duration: 900
                loops: Animation.Infinite
                running: btn.spinning
            }
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    // ── header ────────────────────────────────────────────────────────────────
    Item {
        id: header
        width: root.width
        height: root.headerH

        Text {
            id: headerIcon
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: !BlueZ.powered ? String.fromCodePoint(0xF00B2)      // 󰂲 off
                : root.connectedDevice ? String.fromCodePoint(0xF00B1) // 󰂱 connected
                : String.fromCodePoint(0xF00AF)                        // 󰂯 on
            color: "#f7f7f7"
            font.pixelSize: 24
        }

        Column {
            anchors.left: headerIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: "Bluetooth"
                color: "#f7f7f7"
                font.pixelSize: 16
                font.bold: true
            }
            Text {
                text: root.subtitle
                color: "#9a9a9a"
                font.pixelSize: 13
                width: 200
                elide: Text.ElideRight
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // on/off switch
            Rectangle {
                id: sw
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool on: BlueZ.powered
                width: 48; height: 26; radius: 13
                color: on ? "#3b3b3b" : "#1e1e1e"
                border.width: 1
                border.color: "#2a2a2a"
                opacity: BlueZ.available ? 1 : 0.4

                Rectangle {
                    width: 20; height: 20; radius: 10
                    y: 3
                    x: sw.on ? sw.width - width - 3 : 3
                    color: sw.on ? "#f7f7f7" : "#6a6a6a"
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: BlueZ.available
                    onClicked: BlueZ.togglePower()
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: String.fromCodePoint(0xF0450)   // 󰑐 scan / refresh
                spinning: BlueZ.isScanning
                visible: root.ready
                onClicked: BlueZ.toggleScan()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: String.fromCodePoint(0xF0156)   // 󰅖 close
                onClicked: IslandState.send(IslandState.Event.Back)
            }
        }
    }

    // ── state messages (no adapter / off / empty) ─────────────────────────────
    Item {
        y: root.headerH
        width: root.width
        height: root.stateH
        visible: root.stateH > 0

        Text {
            x: 16; anchors.verticalCenter: parent.verticalCenter
            text: !BlueZ.available ? "No Bluetooth adapter found"
                : !BlueZ.powered   ? "Bluetooth is off"
                : BlueZ.isScanning ? "Scanning…"
                : "No devices found"
            color: !BlueZ.available ? "#ff6b6b" : "#9a9a9a"
            font.pixelSize: 14
        }
    }

    // ── device list ───────────────────────────────────────────────────────────
    Flickable {
        id: list
        y: root.headerH + root.stateH
        width: root.width
        height: root.listH
        contentHeight: col.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        visible: root.ready

        Column {
            id: col
            width: list.width

            Repeater {
                model: BlueZ.devices

                delegate: Item {
                    id: row
                    required property var modelData

                    width: col.width
                    height: root.rowH

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: rowArea.containsMouse ? "#1e1e1e" : "transparent"
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.activate(modelData)
                    }

                    Text {
                        id: devIcon
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(modelData.connected ? 0xF00B1 : 0xF00AF)
                        color: modelData.connected ? "#f7f7f7" : "#9a9a9a"
                        font.pixelSize: 17
                    }

                    Text {
                        anchors.left: devIcon.right
                        anchors.leftMargin: 12
                        anchors.right: status.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name || modelData.address
                        color: "#f7f7f7"
                        font.pixelSize: 14
                        font.bold: modelData.connected
                        elide: Text.ElideRight
                    }

                    Row {
                        id: status
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {   // 󰄬 check
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.connected && !rowArea.containsMouse
                            text: String.fromCodePoint(0xF012C)
                            color: "#f7f7f7"
                            font.pixelSize: 15
                        }
                        Text {   // hover hint on the active device
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.connected && rowArea.containsMouse
                            text: "disconnect"
                            color: "#ff6b6b"
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}