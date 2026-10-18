import QtQuick
import QtQuick.Layouts
import qs.modules.taskbar
import qs.modules.services

// Pinned view. implicitWidth/Height tell the island how big to morph.
FocusScope {
    id: root

    Component.onCompleted: {
        root.forceActiveFocus()
        NetworkManager.refresh()
        NetworkManager.rescan()
    }
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
    implicitHeight: headerH + stateH + listH + errH

    readonly property int rowH:     48
    readonly property int passH:    52
    readonly property int headerH:  70
    readonly property int maxListH: 5 * rowH

    readonly property bool ready: NetworkManager.available && NetworkManager.enabled
    readonly property int stateH: (!ready || NetworkManager.networks.length === 0) ? rowH : 0
    readonly property int listH:  ready
        ? Math.min(list.contentHeight, maxListH + (expandedSsid !== "" ? passH : 0))
        : 0
    readonly property int errH:   NetworkManager.lastError !== "" ? 36 : 0

    // SSID whose password prompt is open ("" = none)
    property string expandedSsid: ""
    onExpandedSsidChanged: NetworkManager.holdOrder = expandedSsid !== ""

    // close the prompt once we're actually connected to that network
    Connections {
        target: NetworkManager
        function onSsidChanged() {
            if (NetworkManager.ssid === root.expandedSsid) root.expandedSsid = ""
        }
    }

    function activate(net) {
        if (net.connecting) return
        if (net.connected) { NetworkManager.disconnect(); return }
        if (net.saved || !net.secured) {
            expandedSsid = ""
            NetworkManager.connectTo(net.ssid, "")
            return
        }
        expandedSsid = (expandedSsid === net.ssid) ? "" : net.ssid
    }

    readonly property string subtitle: {
        if (!NetworkManager.available) return "No adapter"
        if (!NetworkManager.enabled)   return "Off"
        if (NetworkManager.connectingSsid !== "") return "Connecting to " + NetworkManager.connectingSsid + "…"
        if (NetworkManager.connected)  return NetworkManager.ssid
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
            text: NetworkManager.icon
            color: "#f7f7f7"
            font.pixelSize: 24
        }

        Column {
            anchors.left: headerIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: "Network"
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
                readonly property bool on: NetworkManager.enabled
                width: 48; height: 26; radius: 13
                color: on ? "#3b3b3b" : "#1e1e1e"
                border.width: 1
                border.color: "#2a2a2a"
                opacity: NetworkManager.available ? 1 : 0.4

                Rectangle {
                    width: 20; height: 20; radius: 10
                    y: 3
                    x: sw.on ? sw.width - width - 3 : 3
                    color: sw.on ? "#f7f7f7" : "#6a6a6a"
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: NetworkManager.available
                    onClicked: NetworkManager.togglePower()
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: String.fromCodePoint(0xF0450)   // 󰑐 refresh
                spinning: NetworkManager.isScanning
                visible: root.ready
                onClicked: NetworkManager.rescan()
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
            text: !NetworkManager.available ? "No network adapter found"
                : !NetworkManager.enabled   ? "Network is off"
                : NetworkManager.isScanning ? "Scanning…"
                : "No networks found"
            color: !NetworkManager.available ? "#ff6b6b" : "#9a9a9a"
            font.pixelSize: 14
        }
    }

    // ── network list ──────────────────────────────────────────────────────────
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
                model: NetworkManager.networks

                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property bool expanded: root.expandedSsid === modelData.ssid

                    width: col.width
                    height: root.rowH + (expanded ? root.passH : 0)

                    onExpandedChanged: {
                        if (expanded) { passInput.text = ""; passInput.forceActiveFocus() }
                        else root.forceActiveFocus()
                    }

                    // main row
                    Item {
                        id: main
                        width: parent.width
                        height: root.rowH

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: rowArea.containsMouse || row.expanded ? "#1e1e1e" : "transparent"
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (modelData.saved) NetworkManager.forget(modelData.ssid)
                                } else {
                                    root.activate(modelData)
                                }
                            }
                        }

                        Text {
                            id: sigIcon
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: NetworkManager.signalIcon(modelData.signal)
                            color: modelData.connected ? "#f7f7f7" : "#9a9a9a"
                            font.pixelSize: 17
                        }

                        Text {
                            anchors.left: sigIcon.right
                            anchors.leftMargin: 12
                            anchors.right: status.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.ssid
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

                            Text {   // 󰌾 lock
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.secured
                                text: String.fromCodePoint(0xF033E)
                                color: "#9a9a9a"
                                font.pixelSize: 14
                            }
                            Text {   // connecting…
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.connecting
                                text: "…"
                                color: "#9a9a9a"
                                font.pixelSize: 15
                            }
                            Text {   // 󰄬 check
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.connected && !rowArea.containsMouse
                                text: String.fromCodePoint(0xF012C)
                                color: "#f7f7f7"
                                font.pixelSize: 15
                            }
                            Text {   // hover hint on the active network
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.connected && rowArea.containsMouse
                                text: "disconnect"
                                color: "#ff6b6b"
                                font.pixelSize: 13
                            }
                        }
                    }

                    // password prompt
                    Item {
                        y: root.rowH
                        width: parent.width
                        height: root.passH
                        visible: row.expanded

                        Rectangle {
                            id: passBox
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 32 - 8 - 80
                            height: 36
                            radius: 8
                            color: "#1a1a1a"
                            border.width: 1
                            border.color: passInput.activeFocus ? "#4a4a4a" : "#2a2a2a"

                            TextInput {
                                id: passInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: "#f7f7f7"
                                font.pixelSize: 14
                                selectByMouse: true
                                clip: true
                                onAccepted: if (text.length > 0) NetworkManager.connectTo(modelData.ssid, text)
                                Keys.onEscapePressed: root.expandedSsid = ""
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: passInput.text === ""
                                text: "Password"
                                color: "#6a6a6a"
                                font.pixelSize: 14
                            }
                        }

                        Rectangle {
                            anchors.left: passBox.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 80; height: 36; radius: 8
                            color: joinArea.containsMouse ? "#ffffff" : "#f7f7f7"
                            opacity: passInput.text.length > 0 ? 1 : 0.4

                            Text {
                                anchors.centerIn: parent
                                text: modelData.connecting ? "…" : "connect"
                                color: "#111111"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                id: joinArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: passInput.text.length > 0
                                onClicked: NetworkManager.connectTo(modelData.ssid, passInput.text)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── error line ────────────────────────────────────────────────────────────
    Item {
        y: root.headerH + root.stateH + root.listH
        width: root.width
        height: root.errH
        visible: root.errH > 0

        Text {
            x: 16
            width: parent.width - 32
            anchors.verticalCenter: parent.verticalCenter
            text: NetworkManager.lastError
            color: "#ff6b6b"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
}