import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Wi-Fi and Ethernet. Scans while it's on screen.
//   click a network: connect (a new secured one asks for its password first)
//   click the connected one: its actions (disconnect, forget)
//   the password row stays open while connecting, closes once connected, and stays for another
//   try if it fails. While a row is open the list keeps its order, so nothing moves under you.
//   Escape in the password field closes it; a second Escape goes back
Item {
    id: root

    readonly property int rowH: 62
    readonly property int maxRows: 6

    // the network whose row is open (password field or actions)
    property var selected: null
    // the list's order when that row opened; networks that vanish since drop out, new ones wait
    property var frozen: []
    readonly property var shown: selected ? frozen.filter(n => Net.networks.includes(n)) : Net.networks

    function open(n) { frozen = Net.networks.slice(); selected = n }
    function close()  { selected = null }

    function choose(n) {
        if (selected === n) { close(); return }
        if (n.connected || Net.needsPassword(n)) { open(n); return }
        close()
        if (!Net.busy(n)) Net.connect(n)
    }

    // the open network came up (password row) or went down (actions row): that row is done
    Connections {
        target: root.selected
        function onConnectedChanged() { root.close() }
    }

    Component.onCompleted: Net.scan(true)
    Component.onDestruction: Net.scan(false)

    implicitWidth: 440
    implicitHeight: column.implicitHeight + 32

    Column {
        id: column
        x: 16; y: 16
        width: parent.width - 32
        spacing: 8

        Header {
            width: parent.width
            title: "Internet"
            subtitle: Net.attempt ? "Connecting to " + Net.attempt.name + "…" : Net.summary
            onBack: Engine.back()

            Toggle {
                checked: Net.wifiEnabled
                enabled: Net.available && !Net.wifiBlocked
                onToggled: on => Net.setWifi(on)
            }
        }

        ListEntry {
            visible: Net.wired !== null && Net.ethernet
            width: parent.width
            icon: "lan"
            title: "Ethernet"
            subtitle: Net.linkSpeed > 0 ? "Connected  ·  " + Net.linkSpeed + " Mb/s" : "Connected"
            active: true
            activeFocusOnTab: false
        }

        Text {
            visible: text !== ""
            width: parent.width
            topPadding: 6
            bottomPadding: 6
            horizontalAlignment: Text.AlignHCenter
            text: !Net.available ? "NetworkManager isn't running"
                : Net.wifi === null ? "No Wi-Fi device"
                : Net.wifiBlocked ? "Wi-Fi is blocked by a hardware switch or rfkill"
                : !Net.wifiEnabled ? "Wi-Fi is off"
                : Net.networks.length === 0 ? "Searching…" : ""
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        ScrollList {
            width: parent.width
            maxHeight: root.maxRows * root.rowH + (root.selected ? 52 : 0)
            spacing: 2

            Repeater {
                // ScriptModel: an update (a scan, a signal change) moves, adds and removes rows. A
                // plain array rebuilt every row each time: a stall while the island morphs in, and a
                // half-typed password lost
                model: ScriptModel { values: Net.wifiEnabled ? root.shown : [] }

                Column {
                    id: entry
                    required property var modelData
                    required property int index
                    readonly property var net: modelData
                    readonly property bool open: root.selected === net
                    readonly property bool connecting: Net.attempt === net || Net.busy(net)

                    width: parent.width
                    spacing: 4

                    ListEntry {
                        width: parent.width
                        // the keyboard starts on the list, not on the Wi-Fi switch above it
                        focus: entry.index === 0
                        title: entry.net.name
                        active: entry.net.connected
                        subtitle: entry.connecting ? (entry.net.connected ? "Disconnecting…" : "Connecting…")
                                : entry.net.connected ? "Connected"
                                : entry.net.known ? "Saved"
                                : Net.secured(entry.net) ? "Secured" : "Open"
                        icon: Net.glyph(entry.net.signalStrength)
                        onClicked: root.choose(entry.net)

                        Icon {
                            visible: Net.secured(entry.net)
                            name: "lock"
                            size: 16
                            color: entry.net.connected ? Config.secondaryInk : Config.dim
                        }
                    }

                    // ---- the open row: a password, or the network's actions ----
                    Row {
                        visible: entry.open && !entry.net.connected
                        x: 62
                        width: parent.width - 62
                        height: visible ? 44 : 0
                        spacing: 8

                        Rectangle {
                            width: parent.width - join.width - parent.spacing
                            height: 40
                            radius: height / 2
                            color: Config.high
                            border.width: password.activeFocus ? 2 : 0
                            border.color: Config.primary

                            TextInput {
                                id: password
                                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                enabled: !entry.connecting
                                color: Config.text
                                font.family: Config.font
                                font.pixelSize: Config.body
                                clip: true

                                // the field accepts its keys, so ViewLoader never sees them: report them here
                                Keys.onPressed: event => { Engine.key(); event.accepted = false }
                                Keys.onReturnPressed: join.press()
                                Keys.onEnterPressed:  join.press()
                                Keys.onEscapePressed: root.close()

                                Text {
                                    visible: password.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: entry.connecting ? "Connecting…" : "Password"
                                    color: Config.dim
                                    font: password.font
                                }
                            }
                        }

                        Pill {
                            id: join
                            implicitHeight: 40
                            kind: "filled"
                            text: entry.connecting ? "…" : "Connect"
                            enabled: password.text.length >= 8 && !entry.connecting     // WPA: 8..63 characters
                            onClicked: {
                                Net.connect(entry.net, password.text)
                                password.text = ""
                            }
                        }
                    }

                    Row {
                        visible: entry.open && entry.net.connected
                        x: 62
                        height: visible ? 40 : 0
                        spacing: 8

                        Pill {
                            icon: "link_off"
                            text: "Disconnect"
                            onClicked: Net.disconnect(entry.net)
                        }
                        Pill {
                            icon: "delete"
                            text: "Forget"
                            onClicked: { Net.forget(entry.net); root.close() }
                        }
                    }

                    // focus the field as soon as it appears, and again after a failed try
                    onOpenChanged: if (open && !net.connected) password.forceActiveFocus()
                    onConnectingChanged: if (open && !connecting && !net.connected) password.forceActiveFocus()
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
            font.pixelSize: Config.small
        }
    }
}
