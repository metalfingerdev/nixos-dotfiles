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
                    const parsed = JSON.parse(text.trim() || "[]")
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
                    root.monitors = JSON.parse(text.trim() || "[]")
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
                    const parsed = JSON.parse(text.trim() || "[]")
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
