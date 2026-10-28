pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Knows Hyprland's monitors, workspaces and windows. Knows nothing about the island.
//
// The window GEOMETRY the overview needs (at, size, floating, stacking) only comes from
// `hyprctl clients -j`, so this reads hyprctl. It only does so while someone holds a
// watch(true) (the Workspaces view, while it's open): every 2.5 s, and on Hyprland's events
// (debounced). An identical payload is not republished, so live previews aren't rebuilt for nothing.
//
// Every action dispatches in the syntax Hyprland expects (Hyprland.usingLua: the Lua config's
// `hl.dsp.*`, otherwise the classic dispatchers), so empty workspaces and single windows can be
// targeted, not only the workspaces Quickshell already has objects for.
Singleton {
    id: root

    // ---- Quickshell's own objects (always live) ----
    readonly property var focused: Hyprland.focusedWorkspace
    readonly property var activeWindow: Hyprland.activeToplevel

    // ---- hyprctl's view (live while watched) ----
    property var allWorkspaces: []        // raw, including special ones
    property var workspaces: []           // regular ones: { id, name, monitor, windows }, by id
    property var monitors: []
    property var windowList: []
    property var windowByAddress: ({})
    property var workspaceIds: []
    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? -1
    readonly property int count: workspaces.length

    // ---- live regular workspaces: Quickshell's own objects, so indicators need no hyprctl ----
    readonly property var live: Array.from(Hyprland.workspaces.values).filter(w => w.id > 0).sort((a, b) => a.id - b.id)
    function liveWorkspace(id) { return live.find(w => w.id === id) ?? null }
    function occupied(id) {
        const w = liveWorkspace(id)
        return !!w && (w.toplevels?.values?.length ?? w.lastIpcObject?.windows ?? 0) > 0
    }
    // How many workspaces the indicators show (the switcher's dots, the numbered buttons), like
    // GNOME: every one up to the last in use (or the focused one), then one empty one after it.
    readonly property int shown: Math.max(1, Math.min(Math.max(10, activeId), span(1) + 1))

    // how many workspaces an indicator shows: every existing one and the focused one, at least
    // `least`, at most 10 (more only when the focused one is further out)
    function span(least) {
        let top = Math.max(least || 1, activeId)
        for (const w of live) top = Math.max(top, w.id)
        return Math.min(Math.max(10, activeId), top)
    }

    property int watchers: 0
    function watch(on) {
        watchers = Math.max(0, watchers + (on ? 1 : -1))
        if (on) refresh()
    }

    // ---- actions ----
    function dispatch(lua, classic) { Hyprland.dispatch(Hyprland.usingLua ? lua : classic) }

    function focus(id) {
        const ws = Number(id)
        if (!Number.isFinite(ws) || ws <= 0) return
        dispatch("hl.dsp.focus({workspace = '" + ws + "'})", "workspace " + ws)
    }
    function focusWindow(address) {
        if (address) dispatch("hl.dsp.focus({ window = 'address:" + address + "' })", "focuswindow address:" + address)
    }
    function closeWindow(address) {
        if (address) dispatch("hl.dsp.window.close('address:" + address + "')", "closewindow address:" + address)
    }
    function moveWindowToWorkspace(address, workspaceId) {
        const ws = Number(workspaceId)
        if (!address || !Number.isFinite(ws) || ws <= 0) return
        dispatch("hl.dsp.window.move({workspace = '" + ws + "', follow = false, window = 'address:" + address + "'})",
                 "movetoworkspacesilent " + ws + ", address:" + address)
    }
    function moveWindowToSpecial(address, name) {
        const special = String(name || "").trim()
        if (!address || special.length === 0) return
        dispatch("hl.dsp.window.move({workspace = 'special:" + special + "', follow = false, window = 'address:" + address + "'})",
                 "movetoworkspacesilent special:" + special + ", address:" + address)
    }
    function toggleSpecial(name) {
        const special = String(name || "").trim()
        if (special.length > 0)
            dispatch("hl.dsp.workspace.toggle_special('" + special + "')", "togglespecialworkspace " + special)
    }
    // step through ids min..max, wrapping
    function stepWorkspace(delta, minId, maxId) {
        const d = Number(delta)
        if (!d || !(maxId >= minId)) return
        let target = (activeId > 0 ? activeId : minId) + d
        if (target < minId) target = maxId
        if (target > maxId) target = minId
        focus(target)
    }

    // ---- glass: Hyprland's (hypr/modules/look.lua) ----
    // Every window is drawn at decoration.active_opacity over Hyprland's blur, and the `glass` layer
    // rule blurs layers named glass:*. The island is one of those and takes the windows' opacity,
    // read here at start and again each time Hyprland reloads its config.
    property real windowOpacity: 1
    function readOpacity() { opacityProc.running = true }
    Process {
        id: opacityProc
        command: ["hyprctl", "getoption", "decoration:active_opacity", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = Number(JSON.parse(text).float)
                    if (v > 0 && v <= 1) root.windowOpacity = v
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event?.name === "configreloaded") root.readOpacity() }
    }
    Component.onCompleted: readOpacity()

    // ---- queries (all read the properties above, so bindings stay live) ----
    function isSpecial(win) { return String(win?.workspace?.name ?? "").startsWith("special:") }
    function specialWorkspaceName(win) {
        const name = String(win?.workspace?.name ?? "")
        return name.startsWith("special:") ? name.slice(8) : ""
    }
    function nextSpecialWorkspaceName(taken) {
        const used = new Set((taken || []).map(n => String(n).trim().toLowerCase()))
        if (!used.has("stash")) return "stash"
        let i = 2
        while (used.has("stash-" + i)) i++
        return "stash-" + i
    }
    function monitorById(id) {
        const wanted = Number(id)
        return Number.isFinite(wanted) ? monitors.find(m => Number(m.id) === wanted) ?? null : null
    }
    // highest existing regular workspace id >= fromId, or -1
    function highestId(fromId) {
        let highest = -1
        for (const id of workspaceIds) if (id >= fromId && id > highest) highest = id
        return highest
    }

    // Special workspaces on a monitor: configured names first, then the ones Hyprland lists for
    // it, then the ones that only exist because a window sits in them. monitorId < 0 = any monitor.
    function specialWorkspaceNames(monitorName, monitorId, configured) {
        const out = []
        const push = v => { const n = String(v ?? "").trim(); if (n.length > 0 && !out.includes(n)) out.push(n) }
        for (const n of (configured || [])) push(n)
        for (const ws of allWorkspaces) {
            const name = String(ws?.name ?? "")
            if (!name.startsWith("special:")) continue
            if (monitorName && String(ws?.monitor ?? "") !== String(monitorName)) continue
            push(name.slice(8))
        }
        const byMonitor = Number.isFinite(Number(monitorId)) && Number(monitorId) >= 0
        for (const win of windowList) {
            if (byMonitor && Number(win?.monitor ?? -1) !== Number(monitorId)) continue
            push(specialWorkspaceName(win))
        }
        return out
    }

    // Bounding box of the windows in a special workspace on a monitor (layout coordinates).
    function specialGeometry(name, monitorId) {
        let minX = null, minY = null, maxX = null, maxY = null
        for (const win of windowList) {
            if (Number(win?.monitor ?? -1) !== Number(monitorId ?? -1)) continue
            if (specialWorkspaceName(win) !== String(name ?? "").trim()) continue
            const x = win?.at?.[0], y = win?.at?.[1], w = win?.size?.[0], h = win?.size?.[1]
            if (![x, y, w, h].every(Number.isFinite)) continue
            minX = minX === null ? x : Math.min(minX, x)
            minY = minY === null ? y : Math.min(minY, y)
            maxX = maxX === null ? x + w : Math.max(maxX, x + w)
            maxY = maxY === null ? y + h : Math.max(maxY, y + h)
        }
        const found = minX !== null
        return { x: minX, y: minY, width: found ? Math.max(1, maxX - minX) : null, height: found ? Math.max(1, maxY - minY) : null }
    }

    // Compositor stacking, bottom -> top: tiled < floating < pinned, then older focus < newer.
    function stackCompare(a, b) {
        if (!!a?.pinned !== !!b?.pinned) return a?.pinned ? 1 : -1
        if (!!a?.floating !== !!b?.floating) return a?.floating ? 1 : -1
        return Number(b?.focusHistoryID ?? 0) - Number(a?.focusHistoryID ?? 0)
    }
    // the same order as a z value, for windows drawn without a global order (special tiles)
    function specialStackZ(win) {
        return (win?.pinned ? 200000 : 0) + (win?.floating ? 100000 : 0) + 10000 - Number(win?.focusHistoryID ?? 9999)
    }

    // the app a window (hyprctl client) belongs to, and its icon ("" if none)
    function iconOf(win) {
        const app = String(win?.class ?? "")
        if (app === "") return ""
        DesktopEntries.applications.values          // re-run when the entry index updates
        const entry = DesktopEntries.heuristicLookup(app)
        return Quickshell.iconPath(entry?.icon || app.toLowerCase(), true)
    }

    // ---- reading hyprctl ----
    property bool needWindows: false
    property bool needMonitors: false
    property bool needWorkspaces: false
    property string lastClients: ""
    property string lastMonitors: ""
    property string lastWorkspaces: ""

    function refresh() { schedule(true, true, true) }
    function schedule(windows, monitors, workspaces) {
        if (watchers === 0) return
        needWindows = needWindows || windows
        needMonitors = needMonitors || monitors
        needWorkspaces = needWorkspaces || workspaces
        debounce.restart()
    }
    function flush() {
        if (needWindows) { needWindows = false; windowsProc.running = true }
        if (needMonitors) { needMonitors = false; monitorsProc.running = true }
        if (needWorkspaces) { needWorkspaces = false; workspacesProc.running = true }
    }

    Timer { id: debounce; interval: 50; onTriggered: root.flush() }
    Timer { interval: 2500; repeat: true; running: root.watchers > 0; onTriggered: root.refresh() }

    Connections {
        target: Hyprland
        enabled: root.watchers > 0
        function onRawEvent(event) {
            const name = String(event?.name ?? "")
            // previews (screencast) and this shell's own layers fire these constantly: reacting
            // would feed back into more captures
            if (name === "openlayer" || name === "closelayer" || name === "screencast") return
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle", "windowtitlev2"].includes(name))
                root.schedule(true, false, true)
            else if (["workspace", "workspacev2", "focusedmon", "focusedmonv2", "activewindow", "activewindowv2"].includes(name))
                root.schedule(false, false, true)
            else
                root.schedule(true, true, true)
        }
    }

    function parse(text, last, apply) {
        const raw = text.trim() || "[]"
        if (raw === root[last]) return
        root[last] = raw
        try { apply(JSON.parse(raw)) } catch (e) { apply([]) }
    }

    Process {
        id: windowsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text, "lastClients", list => {
                root.windowList = list
                const by = {}
                for (const w of list) by[String(w.address ?? "")] = w
                root.windowByAddress = by
            })
        }
    }
    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { onStreamFinished: root.parse(text, "lastMonitors", list => root.monitors = list) }
    }
    Process {
        id: workspacesProc
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text, "lastWorkspaces", list => {
                root.allWorkspaces = list
                root.workspaces = list
                    .map(ws => ({ id: Number(ws.id ?? 0), name: String(ws.name ?? ws.id ?? ""),
                                  monitor: String(ws.monitor ?? ""), windows: Number(ws.windows ?? 0) }))
                    .filter(ws => Number.isFinite(ws.id) && ws.id > 0)
                    .sort((a, b) => a.id - b.id)
                root.workspaceIds = root.workspaces.map(ws => ws.id)
            })
        }
    }
}
