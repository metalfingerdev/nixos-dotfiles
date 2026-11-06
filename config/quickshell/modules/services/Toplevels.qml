pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Desktops knows the GEOMETRY of every window; this knows which handle (what ScreencopyView captures)
// belongs to which. Both return stable objects, so a ScriptModel keeps delegates (and their captures)
// alive across updates.
Singleton {
    id: root

    readonly property var list: ToplevelManager.toplevels.values

    // hyprctl addresses look like "0x55d0c…"; the Hyprland toplevel handle omits the prefix
    function addressOf(toplevel) {
        const raw = toplevel?.HyprlandToplevel?.address
        return raw ? "0x" + raw : ""
    }
    function dataOf(toplevel) { return Desktops.windowByAddress[addressOf(toplevel)] ?? null }

    function inRange(minId, maxId) {
        const items = []
        for (const t of list) {
            const win = dataOf(t)
            if (!win || Desktops.isSpecial(win)) continue
            const id = Number(win.workspace?.id ?? -1)
            if (id >= minId && id <= maxId) items.push({ t: t, win: win })
        }
        items.sort((a, b) => Desktops.stackCompare(a.win, b.win))
        return items.map(i => i.t)
    }

    function onSpecial(name, monitorId) {
        const items = []
        for (const t of list) {
            const win = dataOf(t)
            if (!win || Number(win.monitor ?? -1) !== Number(monitorId ?? -1)) continue
            if (Desktops.specialWorkspaceName(win) === name) items.push({ t: t, address: addressOf(t) })
        }
        items.sort((a, b) => a.address.localeCompare(b.address))
        return items.map(i => i.t)
    }
}
