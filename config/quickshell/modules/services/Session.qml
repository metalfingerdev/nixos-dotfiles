pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lock is the shell's own lock screen: run("lock") only asks (lockRequested), and Lock.qml locks.
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",     label: "Lock",      icon: "lock",               confirm: false, key: "l" },
        { id: "suspend",  label: "Suspend",   icon: "bedtime",            confirm: false, key: "s" },
        { id: "logout",   label: "Log out",   icon: "logout",             confirm: true,  key: "o" },
        { id: "reboot",   label: "Restart",   icon: "restart_alt",        confirm: true,  key: "r" },
        { id: "poweroff", label: "Shut down", icon: "power_settings_new", confirm: true,  key: "p" }
    ]

    signal lockRequested()

    // logout: Hyprland runs under UWSM (programs.hyprland.withUWSM), so stop that; otherwise end
    // the logind session.
    readonly property var commands: ({
        suspend:  ["systemctl", "suspend"],
        logout:   ["uwsm", "stop"],
        reboot:   ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"]
    })

    function run(id) {
        if (id === "lock") { lockRequested(); return }
        const c = commands[id]
        if (c) Quickshell.execDetached(c)
    }

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
