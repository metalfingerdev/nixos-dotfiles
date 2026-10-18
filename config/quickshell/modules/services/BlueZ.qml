pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Talks to BlueZ via bluetoothctl subprocesses.
// Polls every 3 s; also re-polls after any action.
Singleton {
    id: root

    readonly property bool available:  _available
    readonly property bool powered:    _powered
    readonly property bool connected:  _connected
    readonly property bool isScanning: _scanning

    property bool _available: false
    property bool _powered:   false
    property bool _connected: false
    property bool _scanning:  false

    property list<QtObject> devices: []

    // ── icon helper (Nerd Font) ───────────────────────────────────────────────
    readonly property string icon: {
        if (!_available) return "󰂲"
        if (!_powered)   return "󰂲"
        if (_connected)  return "󰂱"
        return "󰂯"
    }

    // ── poll timer ────────────────────────────────────────────────────────────
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: { showProc.running = true; devicesProc.running = true }
    }

    Component.onCompleted: { showProc.running = true; devicesProc.running = true }

    // ── bluetoothctl show ─────────────────────────────────────────────────────
    Process {
        id: showProc
        command: ["bluetoothctl", "show"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                const t = line.trim()
                if (t.startsWith("Controller"))  root._available   = true
                if (t.startsWith("Powered:"))    root._powered     = t.includes("yes")
                if (t.startsWith("Discovering")) root._scanning    = t.includes("yes")
            }
        }
    }

    // ── bluetoothctl devices ──────────────────────────────────────────────────
    Process {
        id: devicesProc
        command: ["bluetoothctl", "devices"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                const m = line.trim().match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/)
                if (m) infoFetcher.fetch(m[1], m[2])
            }
        }
        onRunningChanged: if (running) infoFetcher.queue = []
    }

    // ── serial info fetcher ───────────────────────────────────────────────────
    QtObject {
        id: infoFetcher
        property var queue: []
        property bool active: false

        function fetch(addr, name) {
            queue.push({ addr, name })
            if (!active) next()
        }
        function next() {
            if (queue.length === 0) { active = false; return }
            active = true
            const item = queue.shift()
            infoProc.addr = item.addr
            infoProc.pendingName = item.name
            infoProc.command = ["bluetoothctl", "info", item.addr]
            infoProc.running = true
        }
    }

    Process {
        id: infoProc
        running: false
        property string addr: ""
        property string pendingName: ""
        property bool _conn: false
        property bool _paired: false

        stdout: SplitParser {
            onRead: line => {
                const t = line.trim()
                if (t.startsWith("Connected:")) infoProc._conn   = t.includes("yes")
                if (t.startsWith("Paired:"))    infoProc._paired = t.includes("yes")
            }
        }

        onRunningChanged: {
            if (running) { _conn = false; _paired = false; return }

            // upsert
            var existing = null
            for (var i = 0; i < root.devices.length; i++) {
                if (root.devices[i].address === addr) { existing = root.devices[i]; break }
            }
            if (existing) {
                existing.connected = _conn
                existing.paired    = _paired
                existing.name      = pendingName
            } else {
                root.devices = root.devices.concat([deviceComponent.createObject(root, {
                    address: addr, name: pendingName,
                    connected: _conn, paired: _paired
                })])
            }

            // recompute top-level connected
            root._connected = root.devices.some(d => d.connected)
            infoFetcher.next()
        }
    }

    Component {
        id: deviceComponent
        QtObject {
            property string address:   ""
            property string name:      ""
            property bool   connected: false
            property bool   paired:    false

            function connectDevice()    { _action(["bluetoothctl", "connect",    address]) }
            function disconnectDevice() { _action(["bluetoothctl", "disconnect", address]) }

            property Process _proc: Process {
                running: false
                onRunningChanged: if (!running) { showProc.running = true; devicesProc.running = true }
            }
            function _action(cmd) { _proc.command = cmd; _proc.running = true }
        }
    }

    // ── public actions ────────────────────────────────────────────────────────
    function togglePower() {
        powerProc.command = ["bluetoothctl", "power", _powered ? "off" : "on"]
        powerProc.running = true
        _powered = !_powered   // optimistic
    }

    function toggleScan() {
        scanProc.command = ["bluetoothctl", _scanning ? "scan off" : "scan on"]
        scanProc.running = true
    }

    Process { id: powerProc;  running: false; onRunningChanged: if (!running) showProc.running = true }
    Process { id: scanProc;   running: false; onRunningChanged: if (!running) showProc.running = true }
}