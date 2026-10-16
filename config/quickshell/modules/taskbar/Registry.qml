pragma Singleton

import QtQuick

QtObject {
    readonly property var entries: [
        { view: IslandState.View.Idle,       name: "idle",       url: Qt.resolvedUrl("views/Idle.qml"),          hold: 0,    priority: 0, timeout: 3000, keys: true },
        { view: IslandState.View.Media,      name: "media",      url: Qt.resolvedUrl("views/Media.qml"),         hold: 0,    priority: 1, timeout: 2000 },
        { view: IslandState.View.Notify,     name: "notify",     url: Qt.resolvedUrl("views/Notify.qml"),        hold: 3500, priority: 2, timeout: 2000, defer: true },
        { view: IslandState.View.Volume,     name: "volume",     url: Qt.resolvedUrl("views/Volume.qml"),        hold: 1500, priority: 1, timeout: 0 },
        { view: IslandState.View.Compact,    name: "compact",    url: Qt.resolvedUrl("views/Compact.qml"),       hold: 0,    priority: 0, timeout: 0 },
        { view: IslandState.View.Dashboard,  name: "dashboard",  url: Qt.resolvedUrl("views/Dashboard.qml"),     hold: 0,    priority: 1, timeout: 2000 },
        { view: IslandState.View.Brightness, name: "brightness", url: Qt.resolvedUrl("views/Backlight.qml"),     hold: 1500, priority: 1, timeout: 0 },
        { view: IslandState.View.Theme,      name: "theme",      url: Qt.resolvedUrl("views/Theme.qml"),         hold: 0,    priority: 1, timeout: 0 },
        { view: IslandState.View.Bluetooth,  name: "bluetooth",  url: Qt.resolvedUrl("views/Bluetooth.qml"),     hold: 0,    priority: 1, timeout: 0 },
        { view: IslandState.View.Launcher,   name: "launcher",   url: Qt.resolvedUrl("views/Launcher.qml"),      hold: 0,    priority: 1, timeout: 2000, keys: true },
        { view: IslandState.View.Workspaces, name: "workspaces", url: Qt.resolvedUrl("views/Workspaces.qml"),    hold: 0,    priority: 1, timeout: 0 }
    ]

    function get(view)      { return entries.find(e => e.view === view) || null }
    function byName(name)   { return entries.find(e => e.name === name) || null }
    function priority(view) { const e = get(view); return e ? e.priority : -1 }
    function timeout(view)  { const e = get(view); return e ? e.timeout : 0 }
    function wantsKeys(view) { const e = get(view); return !!e && e.keys === true }
    function defers(view)   { const e = get(view); return !!e && e.defer === true && e.hold > 0 }
}