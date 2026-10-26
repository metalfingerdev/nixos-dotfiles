import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Internet, laid out like the dashboard. Scans while it's on screen.
//   the Wi-Fi tile switches Wi-Fi (W); Ethernet shows when a cable is in
//   the networks, two to a row (1-9 pick one): a click connects; a new secured one asks for its
//   password, the connected one offers Disconnect and Forget, in the panel underneath
//   the panel stays while connecting, closes once connected, and stays for another try if it
//   fails. While it's open the list keeps its order, so nothing moves under you.
//   Escape closes the panel, then goes back
Item {
    id: root

    readonly property int pad: 24
    readonly property int tileH: 72
    readonly property int maxRows: 4

    // the network whose panel is open (password or actions)
    property var selected: null
    // the list's order when that panel opened; networks that vanish since drop out, new ones wait
    property var frozen: []
    readonly property var shown: selected ? frozen.filter(n => Net.networks.includes(n)) : Net.networks
    readonly property bool asking: selected !== null && !selected.connected
    readonly property bool connecting: selected !== null && (Net.attempt === selected || Net.busy(selected))

    function open(n) { frozen = Net.networks.slice(); selected = n }
    function close()  { selected = null }

    function choose(n) {
        if (selected === n) { close(); return }
        if (n.connected || Net.needsPassword(n)) { open(n); return }
        close()
        if (!Net.busy(n)) Net.connect(n)
    }
    function status(n) {
        if (Net.attempt === n || Net.busy(n)) return n.connected ? "Disconnecting…" : "Connecting…"
        if (n.connected) return "Connected"
        return (n.known ? "Saved" : Net.secured(n) ? "Secured" : "Open")
    }

    // the open network came up (password panel) or went down (actions panel): that panel is done
    Connections {
        target: root.selected
        function onConnectedChanged() { root.close() }
    }
    // focus the field as soon as it appears, and again after a failed try
    onAskingChanged: if (asking) password.forceActiveFocus()
    onConnectingChanged: if (asking && !connecting) password.forceActiveFocus()

    Component.onCompleted: Net.scan(true)
    Component.onDestruction: Net.scan(false)

    // Escape closes the panel first (the field has its own); otherwise it goes on to "back"
    Keys.onEscapePressed: event => { if (root.selected) { root.close(); Engine.key() } else event.accepted = false }

    implicitWidth: 720
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 16

        Header {
            width: parent.width
            title: "Internet"
            subtitle: Net.attempt ? "Connecting to " + Net.attempt.name + "…" : Net.summary
            onBack: Engine.back()
        }

        Row {
            width: parent.width
            spacing: 12

            QuickTile {
                width: Net.ethernet ? (parent.width - 12) / 2 : parent.width
                implicitHeight: 80
                focus: !Net.wifiEnabled || Net.networks.length === 0
                icon: Net.wifiEnabled ? "wifi" : "wifi_off"
                title: "Wi-Fi"
                subtitle: Net.wifiBlocked ? "Blocked by a hardware switch or rfkill"
                        : !Net.wifiEnabled ? "Off" : Net.current ? Net.current.name : "On"
                on: Net.wifiEnabled
                showSwitch: true
                shortcut: "w"
                enabled: Net.available && !Net.wifiBlocked
                onToggled: Net.setWifi(!Net.wifiEnabled)
            }
            QuickTile {
                visible: Net.ethernet
                width: (parent.width - 12) / 2
                implicitHeight: 80
                activeFocusOnTab: false
                icon: "lan"
                title: "Ethernet"
                subtitle: Net.linkSpeed > 0 ? "Connected  ·  " + Net.linkSpeed + " Mb/s" : "Connected"
                on: true
            }
        }

        Text {
            visible: text !== ""
            width: parent.width
            topPadding: 8
            bottomPadding: 8
            horizontalAlignment: Text.AlignHCenter
            text: !Net.available ? "NetworkManager isn't running"
                : Net.wifi === null ? "No Wi-Fi device"
                : !Net.wifiEnabled ? "Turn Wi-Fi on to see networks"
                : Net.networks.length === 0 ? "Searching…" : ""
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        // ---- the networks ----
        ScrollList {
            id: list
            visible: Net.wifiEnabled && root.shown.length > 0
            width: parent.width
            maxHeight: root.maxRows * (root.tileH + 12) + 2 * inset

            Grid {
                id: grid
                width: list.innerWidth
                columns: 2
                spacing: 12

                Repeater {
                    // ScriptModel: an update (a scan, a signal change) moves, adds and removes tiles
                    // instead of rebuilding them all (a stall while the island morphs in)
                    model: ScriptModel { values: Net.wifiEnabled ? root.shown : [] }

                    QuickTile {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property var net: modelData

                        width: (grid.width - 12) / 2
                        implicitHeight: root.tileH
                        // the keyboard starts on the list, not on the Wi-Fi tile above it
                        focus: index === 0
                        icon: Net.glyph(net.signalStrength)
                        title: net.name
                        subtitle: root.status(net)
                        on: net.connected || root.selected === net
                        shortcut: index < 9 ? String(index + 1) : ""
                        onToggled: root.choose(net)
                    }
                }
            }
        }

        // ---- the panel: a password, or the connected network's actions ----
        Rectangle {
            visible: root.selected !== null
            width: parent.width
            height: panel.implicitHeight + 32
            radius: Config.cardRadius
            color: Config.container

            Column {
                id: panel
                x: 16; y: 16
                width: parent.width - 32
                spacing: 12

                Text {
                    leftPadding: 4
                    text: !root.selected ? "" : root.asking ? "Connect to " + root.selected.name : root.selected.name
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: Config.large
                    font.weight: Font.Medium
                }

                Row {
                    visible: root.asking
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: parent.width - join.width - cancel.width - 2 * parent.spacing
                        height: 52
                        radius: height / 2
                        color: Config.high
                        border.width: password.activeFocus ? 2 : 0
                        border.color: Config.primary

                        TextInput {
                            id: password
                            anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            enabled: !root.connecting
                            color: Config.text
                            font.family: Config.font
                            font.pixelSize: Config.large
                            clip: true

                            // the field accepts its keys, so ViewLoader never sees them: report them here
                            Keys.onPressed: event => { Engine.key(); event.accepted = false }
                            Keys.onReturnPressed: join.press()
                            Keys.onEnterPressed:  join.press()
                            Keys.onEscapePressed: root.close()

                            Text {
                                visible: password.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.connecting ? "Connecting…" : "Password"
                                color: Config.dim
                                font: password.font
                            }
                        }
                    }
                    Pill {
                        id: join
                        implicitHeight: 52
                        kind: "filled"
                        text: root.connecting ? "Connecting…" : "Connect"
                        enabled: password.text.length >= 8 && !root.connecting      // WPA: 8..63 characters
                        onClicked: {
                            Net.connect(root.selected, password.text)
                            password.text = ""
                        }
                    }
                    Pill {
                        id: cancel
                        implicitHeight: 52
                        kind: "text"
                        text: "Cancel"
                        onClicked: root.close()
                    }
                }

                Row {
                    visible: root.selected !== null && !root.asking
                    spacing: 10

                    Pill {
                        implicitHeight: 52
                        icon: "link_off"
                        text: "Disconnect"
                        shortcut: "x"
                        onClicked: Net.disconnect(root.selected)
                    }
                    Pill {
                        implicitHeight: 52
                        icon: "delete"
                        text: "Forget"
                        shortcut: "f"
                        onClicked: { Net.forget(root.selected); root.close() }
                    }
                    Pill {
                        implicitHeight: 52
                        kind: "text"
                        text: "Cancel"
                        onClicked: root.close()
                    }
                }
            }
        }

        Text {
            visible: Net.lastError !== ""
            width: parent.width
            leftPadding: 12
            text: Net.lastError
            elide: Text.ElideRight
            color: Config.bad
            font.family: Config.font
            font.pixelSize: Config.body
        }

        KeyHints {
            width: parent.width
            keys: [["1–9", "a network"], ["W", "Wi-Fi on/off"], ["Esc", root.selected ? "close the panel" : "back"]]
        }
    }
}
