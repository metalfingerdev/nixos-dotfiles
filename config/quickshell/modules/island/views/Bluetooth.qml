import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Bluetooth devices of the default adapter.
//   click a device: connect / disconnect; a new one is paired, trusted and connected
//   search: discover new devices (stops when the view closes, if this view started it)
Item {
    id: root

    readonly property int maxRows: 7

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

    implicitWidth: 420
    implicitHeight: column.implicitHeight + 24

    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 6

        Header {
            width: parent.width
            icon: Bluez.connected.length > 0 ? "bluetooth_connected" : Bluez.enabled ? "bluetooth" : "bluetooth_disabled"
            title: "Bluetooth"
            subtitle: Bluez.summary
            onBack: Engine.back()

            Pill {
                visible: Bluez.enabled
                icon: "radar"
                text: Bluez.scanning ? "stop" : "search"
                active: Bluez.scanning
                onClicked: Bluez.scan(!Bluez.scanning)
            }
            Toggle {
                checked: Bluez.enabled
                enabled: Bluez.available && !Bluez.blocked
                onToggled: on => Bluez.setEnabled(on)
            }
        }

        Text {
            visible: text !== ""
            width: parent.width
            topPadding: 6
            bottomPadding: 6
            horizontalAlignment: Text.AlignHCenter
            text: !Bluez.available ? "No Bluetooth adapter"
                : Bluez.blocked ? "Bluetooth is blocked by rfkill"
                : !Bluez.enabled ? "Bluetooth is off"
                : Bluez.devices.length === 0 ? (Bluez.scanning ? "Searching…" : "No devices yet: search to find some") : ""
            color: Config.dim
            font.family: Config.font
            font.pixelSize: Config.body
        }

        ScrollList {
            width: parent.width
            maxHeight: root.maxRows * 46

            Repeater {
                model: Bluez.enabled ? Bluez.devices : []

                ListEntry {
                    required property var modelData
                    required property int index
                    width: parent.width
                    focus: index === 0                     // the keyboard starts on the list, not the switch
                    icon: root.glyph(modelData)
                    title: modelData.name || modelData.address
                    subtitle: Bluez.status(modelData)
                    active: modelData.connected
                    onClicked: Bluez.activate(modelData)
                }
            }
        }
    }
}
