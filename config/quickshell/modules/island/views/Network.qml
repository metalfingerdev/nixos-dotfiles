import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Wi-Fi and Ethernet. Scans while it's on screen.
//   click a network: connect (a new secured one asks for its password first)
//   click the connected one: its actions (disconnect, forget)
//   Escape in the password field closes it; a second Escape goes back
Item {
    id: root

    readonly property int maxRows: 6
    readonly property var shown: Net.networks.slice(0, maxRows)

    // the network whose row is open (password field or actions), and why it last failed
    property var selected: null
    property string error: ""

    function choose(n) {
        error = ""
        if (selected === n) { selected = null; return }
        if (n.connected || Net.needsPassword(n)) { selected = n; return }
        selected = null
        if (!Net.busy(n)) Net.connect(n)
    }

    Component.onCompleted: Net.scan(true)
    Component.onDestruction: Net.scan(false)

    implicitWidth: 420
    implicitHeight: column.implicitHeight + 24

    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 6

        Header {
            width: parent.width
            icon: Net.current ? "wifi" : Net.ethernet ? "lan" : Net.wifiEnabled ? "wifi_find" : "wifi_off"
            title: "Network"
            subtitle: Net.summary
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
            subtitle: Net.linkSpeed > 0 ? "Connected · " + Net.linkSpeed + " Mb/s" : "Connected"
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
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.body
        }

        Repeater {
            model: Net.wifiEnabled ? root.shown : []

            Column {
                id: entry
                required property var modelData
                readonly property var net: modelData
                readonly property bool open: root.selected === net

                width: column.width
                spacing: 4

                ListEntry {
                    width: parent.width
                    title: entry.net.name
                    active: entry.net.connected
                    subtitle: Net.busy(entry.net) ? (entry.net.connected ? "Disconnecting…" : "Connecting…")
                            : entry.net.connected ? "Connected"
                            : entry.net.known ? "Saved"
                            : Net.secured(entry.net) ? "Secured" : "Open"
                    lead: Component {
                        SignalBars {
                            strength: entry.net.signalStrength
                            color: entry.net.connected ? Theme.accent : Theme.text
                        }
                    }
                    onClicked: root.choose(entry.net)

                    Icon {
                        visible: Net.secured(entry.net)
                        name: "lock"
                        size: 14
                        color: Theme.faint
                    }
                }

                // ---- the open row: a password, or the network's actions ----
                Row {
                    visible: entry.open && Net.needsPassword(entry.net)
                    x: 42
                    width: parent.width - 42
                    height: visible ? 32 : 0
                    spacing: 8

                    Rectangle {
                        width: parent.width - join.width - parent.spacing
                        height: 30
                        radius: Theme.innerRadius
                        color: Theme.raised
                        border.width: password.activeFocus ? 1 : 0
                        border.color: Theme.faint

                        TextInput {
                            id: password
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.body
                            clip: true

                            // the field accepts its keys, so ViewLoader never sees them: report them here
                            Keys.onPressed: event => { Engine.key(); event.accepted = false }
                            Keys.onReturnPressed: join.press()
                            Keys.onEnterPressed:  join.press()
                            Keys.onEscapePressed: root.selected = null

                            Text {
                                visible: password.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password"
                                color: Theme.faint
                                font: password.font
                            }
                        }
                    }

                    Pill {
                        id: join
                        text: "join"
                        enabled: password.text.length >= 8              // WPA needs 8..63 characters
                        onClicked: {
                            root.error = ""
                            Net.connect(entry.net, password.text)
                            password.text = ""
                            root.selected = null
                        }
                    }
                }

                Row {
                    visible: entry.open && entry.net.connected
                    x: 42
                    height: visible ? 30 : 0
                    spacing: 8

                    Pill {
                        text: "disconnect"
                        onClicked: { Net.disconnect(entry.net); root.selected = null }
                    }
                    Pill {
                        text: "forget"
                        onClicked: { Net.forget(entry.net); root.selected = null }
                    }
                }

                Connections {
                    target: entry.net
                    function onConnectionFailed(reason) { root.error = entry.net.name + ": " + Net.failure(reason) }
                }

                // focus the field as soon as it appears
                onOpenChanged: if (open && Net.needsPassword(net)) password.forceActiveFocus()
            }
        }

        Text {
            visible: root.error !== ""
            width: parent.width
            leftPadding: 10
            text: root.error
            elide: Text.ElideRight
            color: Theme.bad
            font.family: Theme.font
            font.pixelSize: Theme.small
        }

        Text {
            visible: Net.wifiEnabled && Net.networks.length > root.maxRows
            width: parent.width
            leftPadding: 10
            text: "+" + (Net.networks.length - root.maxRows) + " more"
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: Theme.small
        }
    }
}
