pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Talks to NetworkManager via nmcli subprocesses (same approach as BlueZ.qml).
// Polls every 4 s, rescans every 20 s; also re-polls after any action.
Singleton {
    id: root

    readonly property bool   available:  _available
    readonly property bool   enabled:    _enabled
    readonly property bool   connected:  _ssid !== ""
    readonly property bool   isScanning: scanProc.running || settleTimer.running
    readonly property string ssid:       _ssid
    readonly property int    signal:     _signal
    readonly property string device:     _device
    readonly property string lastError:  _error
    readonly property string connectingSsid: _connectingSsid

    property bool   _available: false
    property bool   _enabled:   false
    property string _ssid:      ""
    property int    _signal:    0
    property string _device:    ""
    property string _error:     ""
    property string _connectingSsid: ""
    property var    _saved: []

    // Set true while the UI has a row expanded (password prompt) so the list
    // is not re-created underneath the user. Values still update in place.
    property bool holdOrder: false

    property list<QtObject> networks: []

    // ── icon helpers (Nerd Font) ──────────────────────────────────────────────
    function signalIcon(s) {
        if (s >= 80) return String.fromCodePoint(0xF0928)   // 󰤨
        if (s >= 60) return String.fromCodePoint(0xF0925)   // 󰤥
        if (s >= 40) return String.fromCodePoint(0xF0922)   // 󰤢
        if (s >= 20) return String.fromCodePoint(0xF091F)   // 󰤟
        return String.fromCodePoint(0xF092F)                // 󰤯
    }

    readonly property string icon: {
        if (!_available || !_enabled) return String.fromCodePoint(0xF092E)  // 󰤮
        if (_ssid === "")             return String.fromCodePoint(0xF092B)  // 󰤫
        return signalIcon(_signal)
    }

    // ── nmcli -t escapes ':' and '\' with a backslash ─────────────────────────
    function _split(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }

    // ── timers ────────────────────────────────────────────────────────────────
    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: root.rescan()
    }

    // keeps the "scanning" state visible for a moment after rescan returns
    Timer {
        id: settleTimer
        interval: 2500
        onTriggered: listProc.running = true
    }

    Timer {
        id: errTimer
        interval: 6000
        onTriggered: root._error = ""
    }

    on_ErrorChanged: if (_error !== "") errTimer.restart()

    Component.onCompleted: { refresh(); rescan() }

    function refresh() {
        statusProc.running = true
        radioProc.running  = true
        savedProc.running  = true
        listProc.running   = true
    }

    function rescan() {
        if (!_enabled) return
        scanProc.running = true
    }

    // ── nmcli device (find the wifi adapter) ──────────────────────────────────
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE", "device"]
        running: false
        property bool found: false
        property string dev: ""
        stdout: SplitParser {
            onRead: line => {
                const f = root._split(line.trim())
                if (f[1] === "wifi" && !statusProc.found) {
                    statusProc.found = true
                    statusProc.dev = f[0]
                }
            }
        }
        onRunningChanged: {
            if (running) { found = false; dev = ""; return }
            root._available = found
            root._device = dev
        }
    }

    // ── nmcli radio wifi ──────────────────────────────────────────────────────
    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: SplitParser {
            onRead: line => root._enabled = line.trim() === "enabled"
        }
    }

    // ── saved profiles ────────────────────────────────────────────────────────
    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        running: false
        property var names: []
        stdout: SplitParser {
            onRead: line => {
                const f = root._split(line.trim())
                if (f[1] === "802-11-wireless") savedProc.names.push(f[0])
            }
        }
        onRunningChanged: {
            if (running) { names = []; return }
            root._saved = names
        }
    }

    // ── visible networks ──────────────────────────────────────────────────────
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
                  "device", "wifi", "list", "--rescan", "no"]
        running: false
        property var rows: []
        stdout: SplitParser {
            onRead: line => {
                const f = root._split(line)
                if (f.length < 4 || f[1] === "") return
                listProc.rows.push({
                    ssid:    f[1],
                    signal:  parseInt(f[2]) || 0,
                    secured: f[3] !== "" && f[3] !== "--",
                    inUse:   f[0] === "*"
                })
            }
        }
        onRunningChanged: {
            if (running) { rows = []; return }
            root._commit(rows)
        }
    }

    Component {
        id: networkComponent
        QtObject {
            property string ssid:    ""
            property int    signal:  0
            property bool   secured: false
            // bindings, so rows update without being re-created
            property bool connected:  root._ssid === ssid
            property bool saved:      root._saved.indexOf(ssid) >= 0
            property bool connecting: root._connectingSsid === ssid
        }
    }

    function _commit(rows) {
        // dedupe by SSID (several APs / bands): in-use wins, then strongest
        const best = {}
        for (const r of rows) {
            const cur = best[r.ssid]
            if (!cur
                || (r.inUse && !cur.inUse)
                || (r.inUse === cur.inUse && r.signal > cur.signal))
                best[r.ssid] = r
        }
        const fresh = Object.keys(best).map(k => best[k])

        // signal is bucketed so the order doesn't jitter on every poll
        fresh.sort((a, b) =>
            (b.inUse - a.inUse)
            || (Math.floor(b.signal / 25) - Math.floor(a.signal / 25))
            || a.ssid.localeCompare(b.ssid))

        const active = fresh.find(r => r.inUse)
        _ssid   = active ? active.ssid   : ""
        _signal = active ? active.signal : 0

        const current = Array.from(networks)
        const byName = {}
        for (const n of current) byName[n.ssid] = n

        // update existing rows in place
        for (const r of fresh) {
            const n = byName[r.ssid]
            if (n) { n.signal = r.signal; n.secured = r.secured }
        }

        if (holdOrder) return

        const next = fresh.map(r => byName[r.ssid] ?? networkComponent.createObject(root, {
            ssid: r.ssid, signal: r.signal, secured: r.secured
        }))

        const same = next.length === current.length && next.every((n, i) => n === current[i])
        if (same) return

        const keep = new Set(next)
        const stale = current.filter(n => !keep.has(n))
        networks = next
        stale.forEach(n => n.destroy())
    }

    // ── public actions ────────────────────────────────────────────────────────
    function togglePower() {
        powerProc.command = ["nmcli", "radio", "wifi", _enabled ? "off" : "on"]
        powerProc.running = true
        _enabled = !_enabled   // optimistic
        if (!_enabled) { _ssid = ""; _signal = 0 }
    }

    // password is only needed for secured networks without a saved profile
    function connectTo(name, password) {
        if (connectProc.running) return
        _error = ""
        connectProc.ssid = name
        connectProc.wasSaved = _saved.indexOf(name) >= 0
        _connectingSsid = name

        if (connectProc.wasSaved && !password) {
            connectProc.command = ["nmcli", "connection", "up", "id", name]
        } else {
            const cmd = ["nmcli", "device", "wifi", "connect", name]
            if (password) cmd.push("password", password)
            connectProc.command = cmd
        }
        connectProc.running = true
    }

    function disconnect() {
        if (_device === "") return
        actionProc.command = ["nmcli", "device", "disconnect", _device]
        actionProc.running = true
    }

    function forget(name) {
        actionProc.command = ["nmcli", "connection", "delete", "id", name]
        actionProc.running = true
    }

    Process {
        id: powerProc
        running: false
        onRunningChanged: if (!running) { root.refresh(); root.rescan() }
    }

    Process {
        id: scanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        running: false
        onRunningChanged: if (!running) settleTimer.restart()
    }

    Process {
        id: actionProc
        running: false
        onRunningChanged: if (!running) root.refresh()
    }

    Process {
        id: connectProc
        running: false
        property string ssid: ""
        property bool wasSaved: false

        stderr: SplitParser {
            onRead: line => { if (line.trim() !== "") root._error = line.trim() }
        }

        onExited: (code, status) => {
            root._connectingSsid = ""
            if (code !== 0) {
                if (root._error === "") root._error = "Couldn't connect to " + ssid
                // a failed first attempt leaves a broken profile behind; drop it
                if (!wasSaved) {
                    cleanupProc.command = ["nmcli", "connection", "delete", "id", ssid]
                    cleanupProc.running = true
                }
            }
            root.refresh()
        }
    }

    Process { id: cleanupProc; running: false }
}