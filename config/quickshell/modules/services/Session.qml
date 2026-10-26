pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Knows how to end, pause or lock the session. Knows nothing about the island.
// Every action is one detached command, so nothing here waits on it.
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",     label: "Lock",      icon: "lock",               confirm: false },
        { id: "suspend",  label: "Suspend",   icon: "bedtime",            confirm: false },
        { id: "logout",   label: "Log out",   icon: "logout",             confirm: true },
        { id: "reboot",   label: "Restart",   icon: "restart_alt",        confirm: true },
        { id: "poweroff", label: "Shut down", icon: "power_settings_new", confirm: true }
    ]

    // lock: asks logind, so whatever locker listens (hypridle -> hyprlock, ...) does the locking.
    // logout: Hyprland runs under UWSM (programs.hyprland.withUWSM), so stop that; otherwise end
    // the logind session.
    readonly property var commands: ({
        lock:     ["loginctl", "lock-session"],
        suspend:  ["systemctl", "suspend"],
        logout:   ["sh", "-c", "uwsm check is-active >/dev/null 2>&1 && exec uwsm stop; "
                             + "exec loginctl terminate-session \"$XDG_SESSION_ID\""],
        reboot:   ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"]
    })

    function run(id) {
        const c = commands[id]
        if (c) Quickshell.execDetached(c)
    }

    // ---- uptime, read on demand (the Power view refreshes it when it opens) ----
    property int uptime: -1              // seconds
    function refresh() { uptimeFile.reload() }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.uptime = Math.floor(parseFloat(text()))
    }

    readonly property string uptimeText: {
        if (uptime < 0) return ""
        const d = Math.floor(uptime / 86400), h = Math.floor(uptime % 86400 / 3600), m = Math.floor(uptime % 3600 / 60)
        return "up " + (d > 0 ? d + " d " : "") + (d > 0 || h > 0 ? h + " h " : "") + m + " min"
    }
}
