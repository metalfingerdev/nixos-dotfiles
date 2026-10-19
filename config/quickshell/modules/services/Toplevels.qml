pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Wayland toplevel handles (what ScreencopyView captures), matched to Hyprland's window data.
// Workspaces.qml knows the *geometry* of every window; this knows which handle belongs to which window.
// Both queries return stable Toplevel objects, so a ScriptModel keeps delegates alive across updates.
Singleton {
    id: root

    readonly property var list: ToplevelManager.toplevels.values

    // hyprctl addresses look like "0x55d0c…"; the Hyprland toplevel handle omits the prefix.
    function addressOf(toplevel) {
        const raw = toplevel?.HyprlandToplevel?.address
        return raw ? "0x" + raw : ""
    }

    function dataOf(toplevel) {
        return Workspaces.windowByAddress[root.addressOf(toplevel)] ?? null
    }

    // Normal-workspace windows whose workspace is in [minId, maxId], sorted bottom -> top.
    function inRange(minId, maxId) {
        const items = []
        for (const toplevel of root.list) {
            const win = root.dataOf(toplevel)
            if (!win || Workspaces.isSpecial(win)) continue
            const id = Number(win.workspace?.id ?? -1)
            if (id < minId || id > maxId) continue
            items.push({ toplevel: toplevel, win: win })
        }
        items.sort((a, b) => Workspaces.stackCompare(a.win, b.win))
        return items.map(item => item.toplevel)
    }

    // Windows parked in the special workspace `name` on a monitor, in a stable (address) order.
    function onSpecial(name, monitorId) {
        const items = []
        for (const toplevel of root.list) {
            const win = root.dataOf(toplevel)
            if (!win || Number(win.monitor ?? -1) !== Number(monitorId ?? -1)) continue
            if (Workspaces.specialWorkspaceName(win) !== name) continue
            items.push({ toplevel: toplevel, address: root.addressOf(toplevel) })
        }
        items.sort((a, b) => a.address.localeCompare(b.address))
        return items.map(item => item.toplevel)
    }
}