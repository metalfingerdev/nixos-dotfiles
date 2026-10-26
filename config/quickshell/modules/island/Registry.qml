pragma Singleton

import QtQuick

QtObject {
    id: registry

    readonly property var entries: [
        { name: "compact",    priority: 0, timeout: 0,    view: Engine.View.Compact,    url: Qt.resolvedUrl("views/Compact.qml") },
        { name: "expanded",   priority: 1, timeout: 1500, view: Engine.View.Expanded,   url: Qt.resolvedUrl("views/Expanded.qml") },
        { name: "network",    priority: 2, timeout: 5000, view: Engine.View.Network,    url: Qt.resolvedUrl("views/Network.qml") },
        { name: "launcher",   priority: 2, timeout: 8000, view: Engine.View.Launcher,   url: Qt.resolvedUrl("views/Launcher.qml") },
        { name: "bluetooth",  priority: 2, timeout: 5000, view: Engine.View.Bluetooth,  url: Qt.resolvedUrl("views/Bluetooth.qml") },
        { name: "volume",     priority: 1, timeout: 1500, view: Engine.View.Volume,     url: Qt.resolvedUrl("views/Volume.qml"),     queue: false },
        { name: "brightness", priority: 1, timeout: 1500, view: Engine.View.Brightness, url: Qt.resolvedUrl("views/Brightness.qml"), queue: false },
        // Toast = popups, Pinned = the center. timeout 0: Notifier times each popup, and Triggers
        // closes the view when the last one goes. `critical`: the priority a critical one alerts with.
        { name: "notifications", priority: 2, critical: 3, timeout: 0, view: Engine.View.Notifications, url: Qt.resolvedUrl("views/Notification.qml"), queue: true }
    ]

    // A non-number (e.g. an enum name that doesn't exist yet: Qt keeps a singleton's old enum across a
    // hot reload) must never match an entry, or the machine would accept a view nothing can show or end.
    function get(view) { return typeof view === "number" ? entries.find(e => e.view === view) || null : null }
    function byName(name)    { return entries.find(e => e.name === name) || null }
    // critical = true: the entry's `critical` priority, if it has one
    function priority(view, critical) {
        const e = get(view)
        if (!e) return -1
        return critical && e.critical !== undefined ? e.critical : e.priority
    }
    function timeout(view)   { const e = get(view); return e ? e.timeout : 0 }
    function queues(view)    { const e = get(view); return e ? !!e.queue : false }
}