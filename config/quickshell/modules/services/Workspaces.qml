pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland workspace model and actions for the island Workspaces view.
Singleton {
    id: root

    property var allWorkspaces: []
    property var workspaces: []
    property var monitors: []
    property var windowList: []
    property var windowByAddress: ({})
    property var workspaceIds: []
    property int activeId: -1
    readonly property int count: workspaces.length

    property bool pendingWindowsUpdate: false
    property bool pendingMonitorsUpdate: false
    property bool pendingWorkspacesUpdate: false
    property bool pendingActiveWorkspaceUpdate: false

    // Last raw hyprctl output per source. The 2.5s poll re-reads everything; publishing an identical
    // payload would re-evaluate every binding (and every live preview) for nothing.
    property string lastClients: ""
    property string lastMonitors: ""
    property string lastWorkspaces: ""

    function refresh() {
        scheduleUpdates(true, true, true, true)
        flushPendingUpdates()
    }

    function scheduleUpdates(windows, monitors, workspaces, activeWorkspace) {
        pendingWindowsUpdate = pendingWindowsUpdate || !!windows
        pendingMonitorsUpdate = pendingMonitorsUpdate || !!monitors
        pendingWorkspacesUpdate = pendingWorkspacesUpdate || !!workspaces
        pendingActiveWorkspaceUpdate = pendingActiveWorkspaceUpdate || !!activeWorkspace
        debounce.restart()
    }

    function flushPendingUpdates() {
        if (pendingWindowsUpdate) {
            pendingWindowsUpdate = false
            windowsProc.running = true
        }
        if (pendingMonitorsUpdate) {
            pendingMonitorsUpdate = false
            monitorsProc.running = true
        }
        if (pendingWorkspacesUpdate) {
            pendingWorkspacesUpdate = false
            workspacesProc.running = true
        }
        if (pendingActiveWorkspaceUpdate) {
            pendingActiveWorkspaceUpdate = false
            activeProc.running = true
        }
    }

    function focus(id) {
        const wsId = Number(id)
        if (!Number.isFinite(wsId) || wsId <= 0) return
        if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.focus({workspace = '" + wsId + "'})")
        else Hyprland.dispatch("workspace " + wsId)
        root.activeId = wsId
    }

    function focusWindow(address) {
        if (!address) return
        if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + address + "' })")
        else Hyprland.dispatch("focuswindow address:" + address)
    }

    function closeWindow(address) {
        if (!address) return
        if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.window.close('address:" + address + "')")
        else Hyprland.dispatch("closewindow address:" + address)
    }

    function moveWindowToWorkspace(address, workspaceId) {
        const wsId = Number(workspaceId)
        if (!address || !Number.isFinite(wsId) || wsId <= 0) return
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.window.move({workspace = '" + wsId + "', follow = false, window = 'address:" + address + "'})")
        else
            Hyprland.dispatch("movetoworkspacesilent " + wsId + ", address:" + address)
    }

    function moveWindowToSpecial(address, name) {
        const special = String(name || "").trim()
        if (!address || special.length === 0) return
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.window.move({workspace = 'special:" + special + "', follow = false, window = 'address:" + address + "'})")
        else
            Hyprland.dispatch("movetoworkspacesilent special:" + special + ", address:" + address)
    }

    function toggleSpecial(name) {
        const special = String(name || "").trim()
        if (special.length === 0) return
        if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.workspace.toggle_special('" + special + "')")
        else Hyprland.dispatch("togglespecialworkspace " + special)
    }

    function stepWorkspace(delta, minWorkspaceId, maxWorkspaceId) {
        const minWs = Number(minWorkspaceId)
        const maxWs = Number(maxWorkspaceId)
        const d = Number(delta)
        if (!Number.isFinite(d) || d === 0) return
        if (!Number.isFinite(minWs) || !Number.isFinite(maxWs) || maxWs < minWs) return

        const current = root.activeId > 0 ? root.activeId : minWs
        let target = current + d
        if (target < minWs) target = maxWs
        if (target > maxWs) target = minWs
        focus(target)
    }

    function specialWorkspaceName(win) {
        const name = String(win?.workspace?.name ?? "")
        return name.startsWith("special:") ? name.slice(8) : ""
    }

    function nextSpecialWorkspaceName(visibleNames) {
        const taken = new Set()
        for (const name of (visibleNames || [])) taken.add(String(name).trim().toLowerCase())

        const base = "stash"
        if (!taken.has(base)) return base
        let idx = 2
        while (taken.has(base + "-" + idx)) idx++
        return base + "-" + idx
    }

    // ---- model queries (used by the Workspaces view; all read the properties above, so bindings stay live) ----

    function isSpecial(win) {
        return String(win?.workspace?.name ?? "").startsWith("special:")
    }

    function monitorById(id) {
        const wanted = Number(id)
        if (!Number.isFinite(wanted)) return null
        return root.monitors.find(m => Number(m.id) === wanted) ?? null
    }

    function workspaceHasWindows(workspaceId) {
        for (let i = 0; i < root.windowList.length; i++) {
            const win = root.windowList[i]
            if (Number(win?.workspace?.id ?? -1) === workspaceId && !root.isSpecial(win)) return true
        }
        return false
    }

    // highest existing (non-special) workspace id >= fromId, or -1
    function highestId(fromId) {
        let highest = -1
        for (let i = 0; i < root.workspaceIds.length; i++) {
            const id = Number(root.workspaceIds[i])
            if (id >= fromId && id > highest) highest = id
        }
        return highest
    }

    // Special workspaces that belong on a monitor: configured names first, then the ones Hyprland lists
    // for that monitor, then the ones that only exist because a window sits in them.
    // monitorId < 0 / undefined disables the per-monitor filter.
    function specialWorkspaceNames(monitorName, monitorId, configured) {
        const out = []
        const push = value => {
            const name = String(value ?? "").trim()
            if (name.length > 0 && !out.includes(name)) out.push(name)
        }
        for (const name of (configured || [])) push(name)

        for (let i = 0; i < root.allWorkspaces.length; i++) {
            const ws = root.allWorkspaces[i]
            const name = String(ws?.name ?? "")
            if (!name.startsWith("special:")) continue
            if (monitorName && String(ws?.monitor ?? "") !== String(monitorName)) continue
            push(name.slice(8))
        }

        const filterByMonitor = Number.isFinite(Number(monitorId)) && Number(monitorId) >= 0
        for (let j = 0; j < root.windowList.length; j++) {
            const win = root.windowList[j]
            if (filterByMonitor && Number(win?.monitor ?? -1) !== Number(monitorId)) continue
            const special = root.specialWorkspaceName(win)
            if (special.length > 0) push(special)
        }
        return out
    }

    // Bounding box of every window in a special workspace on a monitor (global layout coordinates).
    function specialGeometry(name, monitorId) {
        const wanted = String(name ?? "").trim()
        let minX = null, minY = null, maxX = null, maxY = null

        for (let i = 0; i < root.windowList.length; i++) {
            const win = root.windowList[i]
            if (Number(win?.monitor ?? -1) !== Number(monitorId ?? -1)) continue
            if (root.specialWorkspaceName(win) !== wanted) continue

            const x = win?.at?.[0], y = win?.at?.[1]
            const w = win?.size?.[0], h = win?.size?.[1]
            if (!Number.isFinite(x) || !Number.isFinite(y) || !Number.isFinite(w) || !Number.isFinite(h)) continue

            minX = minX === null ? x : Math.min(minX, x)
            minY = minY === null ? y : Math.min(minY, y)
            maxX = maxX === null ? x + w : Math.max(maxX, x + w)
            maxY = maxY === null ? y + h : Math.max(maxY, y + h)
        }

        const found = minX !== null && maxX !== null
        return {
            x: minX,
            y: minY,
            width: found ? Math.max(1, maxX - minX) : null,
            height: found ? Math.max(1, maxY - minY) : null
        }
    }

    // Compositor stacking, bottom -> top: tiled < floating < pinned, then older focus < newer focus.
    function stackCompare(a, b) {
        if (!!a?.pinned !== !!b?.pinned) return a?.pinned ? 1 : -1
        if (!!a?.floating !== !!b?.floating) return a?.floating ? 1 : -1
        return Number(b?.focusHistoryID ?? 0) - Number(a?.focusHistoryID ?? 0)
    }

    // z value for windows that are drawn without a global order (special workspace tiles)
    function specialStackZ(win) {
        const pinned = win?.pinned ? 200000 : 0
        const floating = win?.floating ? 100000 : 0
        const focus = 10000 - Number(win?.focusHistoryID ?? 9999)
        return pinned + floating + focus
    }

    function next() {
        if (root.workspaces.length === 0) return
        const ids = root.workspaces.map(w => Number(w.id)).sort((a, b) => a - b)
        const active = root.activeId > 0 ? root.activeId : ids[0]
        const index = ids.indexOf(active)
        const target = ids[(index + 1) % ids.length] ?? ids[0]
        root.focus(target)
    }

    function previous() {
        if (root.workspaces.length === 0) return
        const ids = root.workspaces.map(w => Number(w.id)).sort((a, b) => a - b)
        const active = root.activeId > 0 ? root.activeId : ids[0]
        const index = ids.indexOf(active)
        const target = ids[(index - 1 + ids.length) % ids.length] ?? ids[0]
        root.focus(target)
    }

    Timer {
        id: poll
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: debounce
        interval: 50
        repeat: false
        onTriggered: root.flushPendingUpdates()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = String(event?.name ?? event?.event ?? event?.type ?? "")
            // Screen capture (live previews) and layer surfaces (this shell) emit these constantly;
            // reacting to them would feed back into more captures.
            if (name === "openlayer" || name === "closelayer" || name === "screencast") return
            if (name === "openwindow" || name === "closewindow" || name === "movewindow" || name === "movewindowv2" || name === "windowtitle") {
                root.scheduleUpdates(true, false, true, false)
                return
            }
            if (name === "workspace" || name === "workspacev2" || name === "focusedmon" || name === "focusedmonv2" || name === "activewindow" || name === "activewindowv2") {
                root.scheduleUpdates(false, false, true, true)
                return
            }
            if (name.startsWith("monitor") || name === "configreloaded") {
                root.scheduleUpdates(true, true, true, true)
                return
            }
            root.scheduleUpdates(true, true, true, true)
        }
    }

    Process {
        id: activeProc
        running: false
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim())
                    root.activeId = Number(parsed?.id ?? -1)
                } catch (e) {
                    root.activeId = -1
                }
            }
        }
    }

    Process {
        id: windowsProc
        running: false
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim() || "[]"
                    if (raw === root.lastClients) return
                    root.lastClients = raw
                    const parsed = JSON.parse(raw)
                    root.windowList = parsed
                    const byAddress = {}
                    for (let i = 0; i < parsed.length; i++) {
                        const win = parsed[i]
                        byAddress[String(win.address ?? "")] = win
                    }
                    root.windowByAddress = byAddress
                } catch (e) {
                    root.windowList = []
                    root.windowByAddress = ({})
                }
            }
        }
    }

    Process {
        id: monitorsProc
        running: false
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim() || "[]"
                    if (raw === root.lastMonitors) return
                    root.lastMonitors = raw
                    root.monitors = JSON.parse(raw)
                } catch (e) {
                    root.monitors = []
                }
            }
        }
    }

    Process {
        id: workspacesProc
        running: false
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim() || "[]"
                    if (raw === root.lastWorkspaces) return
                    root.lastWorkspaces = raw
                    const parsed = JSON.parse(raw)
                    root.allWorkspaces = parsed
                    root.workspaces = parsed
                        .map(ws => ({
                            id: Number(ws.id ?? 0),
                            name: String(ws.name ?? String(ws.id ?? "")),
                            monitor: String(ws.monitor ?? ""),
                            windows: Number(ws.windows ?? 0)
                        }))
                        .filter(ws => Number.isFinite(ws.id) && ws.id > 0)
                        .sort((a, b) => a.id - b.id)
                    root.workspaceIds = root.workspaces.map(ws => ws.id)
                } catch (e) {
                    root.allWorkspaces = []
                    root.workspaces = []
                    root.workspaceIds = []
                }
            }
        }
    }

    Component.onCompleted: root.refresh()
}