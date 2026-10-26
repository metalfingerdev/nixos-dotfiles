import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.services
import qs.modules.components

ShellRoot {
    id: root

    // input adapters: exactly one of each, shared by every screen
    Ipc {}
    Triggers {}
    Debug {}        // live snapshot overlay, hidden until `qs ipc call island debug true`

    // services that must exist from the start (their IPC targets), not only once a view shows them
    readonly property var services: [Wallpaper, Notifier]

    // a theme generated from the wallpaper follows it (Config is plain QtQuick and can't ask)
    Binding { target: Config; property: "wallpaperSeed"; value: Wallpaper.seed }

    // one Bar per screen; only the one on Engine.activeScreen shows the island
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
