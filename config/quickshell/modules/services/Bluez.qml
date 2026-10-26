pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Knows BlueZ (through Quickshell.Bluetooth). Knows nothing about the island.
//
// devices: the default adapter's devices: connected first, then paired, then by name. Devices
//          discovery found that have no name of their own (just an address) are left out.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property bool scanning: adapter?.discovering ?? false

    function setEnabled(on) { if (adapter) adapter.enabled = on }

    readonly property var devices: {
        if (!adapter) return []
        return Array.from(adapter.devices.values)
            .filter(d => d.paired || (d.deviceName !== "" && d.deviceName !== d.address))
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    }
    readonly property var connected: devices.filter(d => d.connected)

    readonly property string summary: {
        if (!available) return "No adapter"
        if (blocked) return "Blocked"
        if (!enabled) return "Off"
        if (connected.length === 1) return connected[0].name
        if (connected.length > 1) return connected.length + " devices connected"
        return scanning ? "Searching…" : "Not connected"
    }

    // ---- discovery: only stopped by whoever started it ----
    property bool ownScan: false
    function scan(on) {
        if (!adapter) return
        if (on && !scanning) { ownScan = true; adapter.discovering = true }
        if (!on && ownScan)  { ownScan = false; adapter.discovering = false }
    }

    // ---- one click per device: connect, disconnect, or pair a new one (then connect it) ----
    function busy(d) { return d.pairing || d.state === BluetoothDeviceState.Connecting
                                        || d.state === BluetoothDeviceState.Disconnecting }
    function activate(d) {
        if (busy(d)) return
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else pair(d)
    }

    // A freshly paired device is trusted (so it may reconnect by itself) and connected.
    property var pending: null
    function pair(d) { pending = d; d.trusted = true; d.pair() }
    Connections {
        target: root.pending
        function onPairedChanged() {
            if (root.pending.paired) root.pending.connect()
            root.pending = null
        }
        function onPairingChanged() {                       // gave up or was refused
            if (!root.pending.pairing && !root.pending.paired) root.pending = null
        }
    }

    function forget(d) { d.forget() }

    // one line per device, for lists
    function status(d) {
        if (d.pairing) return "Pairing…"
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        if (d.connected) return "Connected" + (d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "%" : "")
        return d.paired ? "Paired" : "New · click to pair"
    }
}
