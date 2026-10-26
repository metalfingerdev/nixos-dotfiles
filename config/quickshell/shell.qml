import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.services

ShellRoot {
    id: root

    // input adapters: exactly one of each, shared by every screen
    Ipc {}
    Triggers {}
    Debug {}        // live snapshot overlay, hidden until `qs ipc call island debug true`

    // services that must exist from the start (their IPC targets), not only once a view shows them
    readonly property var services: [Wallpaper, Notifier]

    // one Bar per screen; only the one on Engine.activeScreen shows the island
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
