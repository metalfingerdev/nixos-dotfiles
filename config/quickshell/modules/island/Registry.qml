pragma Singleton

import QtQuick

QtObject {
    id: registry

    readonly property var entries: [
        { name: "compact",    priority: 0, timeout: 0,    view: Engine.View.Compact,    url: Qt.resolvedUrl("views/Compact.qml") },
        // the hub: hovering the clock (Compact) peeks into it, a click opens it
        { name: "tabs",       priority: 2, timeout: 8000, view: Engine.View.Tabs,       url: Qt.resolvedUrl("views/Tabs.qml") },
        // everything: quick settings, sliders, media, notifications
        { name: "dashboard",  priority: 2, timeout: 12000, view: Engine.View.Dashboard, url: Qt.resolvedUrl("views/Dashboard.qml") },
        { name: "network",    priority: 2, timeout: 5000, view: Engine.View.Network,    url: Qt.resolvedUrl("views/Network.qml") },
        { name: "launcher",   priority: 2, timeout: 8000, view: Engine.View.Launcher,   url: Qt.resolvedUrl("views/Launcher.qml") },
        { name: "bluetooth",  priority: 2, timeout: 5000, view: Engine.View.Bluetooth,  url: Qt.resolvedUrl("views/Bluetooth.qml") },
        // a click on these toasts opens the dashboard (both sliders, and everything else)
        { name: "volume",     priority: 1, timeout: 1500, view: Engine.View.Volume,     url: Qt.resolvedUrl("views/Volume.qml"),     queue: false,
          opens: Engine.View.Dashboard },
        { name: "brightness", priority: 1, timeout: 1500, view: Engine.View.Brightness, url: Qt.resolvedUrl("views/Brightness.qml"), queue: false,
          opens: Engine.View.Dashboard },
        // Toast = popups, Pinned = the center. timeout 0: Notifier times each popup, and Triggers
        // closes the view when the last one goes. `critical`: the priority a critical one alerts with.
        { name: "notifications", priority: 2, critical: 3, timeout: 0, view: Engine.View.Notifications, url: Qt.resolvedUrl("views/Notification.qml"), queue: true },
        { name: "media",      priority: 2, timeout: 8000, view: Engine.View.Media,      url: Qt.resolvedUrl("views/Media.qml") },
        // the output, the microphone and every app playing sound, each with its own level
        { name: "mixer",      priority: 2, timeout: 8000, view: Engine.View.Mixer,      url: Qt.resolvedUrl("views/Mixer.qml") },
        // Toast = charger plugged/unplugged or battery low (critical: nearly empty), Pinned = details.
        { name: "battery",    priority: 2, critical: 3, timeout: 4000, view: Engine.View.Battery, url: Qt.resolvedUrl("views/Battery.qml"), queue: true },
        { name: "clock",      priority: 2, timeout: 8000, view: Engine.View.Clock,      url: Qt.resolvedUrl("views/Clock.qml") },
        { name: "power",      priority: 2, timeout: 8000, view: Engine.View.Power,      url: Qt.resolvedUrl("views/Power.qml") },
        // colours and the wallpaper; the island's size, shape and hiding are its settings
        { name: "theme",      priority: 2, timeout: 8000, view: Engine.View.Theme,      url: Qt.resolvedUrl("views/Theme.qml") },
        { name: "settings",   priority: 2, timeout: 8000, view: Engine.View.Settings,   url: Qt.resolvedUrl("views/Settings.qml") },
        { name: "workspaces", priority: 2, timeout: 8000, view: Engine.View.Workspaces, url: Qt.resolvedUrl("views/Workspaces.qml") },
        // Toast = the workspace changed (GNOME-style dots). Transient: never interrupts, never waits.
        // `opens`: a click on the toast opens this instead of pinning the toast (its full view)
        { name: "switcher",   priority: 1, timeout: 1200, view: Engine.View.Switcher,   url: Qt.resolvedUrl("views/Switcher.qml"), queue: false,
          opens: Engine.View.Workspaces }
    ]

    // A non-number (e.g. an enum name that doesn't exist yet: Qt keeps a singleton's old enum across a
    // hot reload) must never match an entry, or the machine would accept a view nothing can show or end.
    function get(view) { return typeof view === "number" ? entries.find(e => e.view === view) || null : null }
    // a name, or one of its aliases
    function byName(name)    { return entries.find(e => e.name === name || (e.aliases ?? []).includes(name)) || null }
    // critical = true: the entry's `critical` priority, if it has one
    function priority(view, critical) {
        const e = get(view)
        if (!e) return -1
        return critical && e.critical !== undefined ? e.critical : e.priority
    }
    function timeout(view)   { const e = get(view); return e ? e.timeout : 0 }
    function queues(view)    { const e = get(view); return e ? !!e.queue : false }
}