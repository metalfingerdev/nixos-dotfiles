import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Bluetooth, laid out like the dashboard: the default adapter's devices.
//   the Bluetooth tile switches it (B); Search finds new devices (S; stops when the view closes,
//   if this view started it)
//   the devices, two to a row (1-9 pick one): a click connects or disconnects; a new one is
//   paired, trusted and connected
Item {
    id: root

    readonly property int pad: 24
    readonly property int tileH: 72
    readonly property int maxRows: 4

    // BlueZ icon names -> Material Symbols
    function glyph(d) {
        const i = d.icon || ""
        if (i.includes("headset") || i.includes("headphone")) return "headphones"
        if (i.startsWith("audio")) return "speaker"
        if (i.includes("mouse")) return "mouse"
        if (i.includes("keyboard")) return "keyboard"
        if (i.includes("gaming")) return "stadia_controller"
        if (i.includes("phone")) return "smartphone"
        if (i.includes("computer")) return "computer"
        if (i.includes("tablet")) return "tablet"
        if (i.includes("watch")) return "watch"
        return "bluetooth"
    }

    Component.onDestruction: Bluez.scan(false)

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
            title: "Bluetooth"
            subtitle: Bluez.summary
            onBack: Engine.back()

            Pill {
                visible: Bluez.enabled
                implicitHeight: 48
                icon: "radar"
                text: Bluez.scanning ? "Stop" : "Search"
                active: Bluez.scanning
                shortcut: "s"
                onClicked: Bluez.scan(!Bluez.scanning)
            }
        }

        QuickTile {
            width: parent.width
            implicitHeight: 80
            focus: !Bluez.enabled || Bluez.devices.length === 0
            icon: Bluez.connected.length > 0 ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
            title: "Bluetooth"
            subtitle: !Bluez.available ? "No adapter" : Bluez.blocked ? "Blocked by rfkill" : !Bluez.enabled ? "Off" : Bluez.summary
            on: Bluez.enabled
            showSwitch: true
            shortcut: "b"
            enabled: Bluez.available && !Bluez.blocked
            onToggled: Bluez.setEnabled(!Bluez.enabled)
        }

        Text {
            visible: text !== ""
            width: parent.width
            topPadding: 8
            bottomPadding: 8
            horizontalAlignment: Text.AlignHCenter
            text: !Bluez.available ? "No Bluetooth adapter"
                : !Bluez.enabled ? "Turn Bluetooth on to see devices"
                : Bluez.devices.length === 0 ? (Bluez.scanning ? "Searching…" : "No devices yet: Search to find some") : ""
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        ScrollList {
            id: list
            visible: Bluez.enabled && Bluez.devices.length > 0
            width: parent.width
            maxHeight: root.maxRows * (root.tileH + 12) + 2 * inset

            Grid {
                id: grid
                width: list.innerWidth
                columns: 2
                spacing: 12

                Repeater {
                    model: Bluez.enabled ? Bluez.devices : []

                    QuickTile {
                        required property var modelData
                        required property int index
                        width: (grid.width - 12) / 2
                        implicitHeight: root.tileH
                        focus: index === 0                     // the keyboard starts on the list
                        icon: root.glyph(modelData)
                        title: modelData.name || modelData.address
                        subtitle: Bluez.status(modelData)
                        on: modelData.connected
                        shortcut: index < 9 ? String(index + 1) : ""
                        onToggled: Bluez.activate(modelData)
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["1–9", "a device"], ["B", "Bluetooth on/off"], ["S", "search"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
