pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Knows Hyprland's workspaces and windows. Knows nothing about the island.
//
// workspaces: the regular ones (special workspaces have negative ids), in id order.
Singleton {
    id: root

    readonly property var workspaces: Array.from(Hyprland.workspaces.values)
        .filter(w => w.id > 0)
        .sort((a, b) => a.id - b.id)
    readonly property var focused: Hyprland.focusedWorkspace
    readonly property var activeWindow: Hyprland.activeToplevel

    function windows(w) { return w ? Array.from(w.toplevels.values) : [] }
    // the app a window belongs to: its Wayland app id, else Hyprland's class
    function appOf(t) { return t?.wayland?.appId || t?.lastIpcObject?.class || "" }
    // an icon path for that app (desktop entry, then the icon theme), or "" if there is none
    function iconOf(t) {
        const app = appOf(t)
        if (app === "") return ""
        const entry = DesktopEntries.heuristicLookup(app)
        return Quickshell.iconPath(entry?.icon || app.toLowerCase(), true)
    }

    function activate(w) { if (w && w !== focused) w.activate() }
}
