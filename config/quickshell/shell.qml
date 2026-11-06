import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.lock
import qs.modules.activatelinux
import qs.modules.services
import qs.modules.components

ShellRoot {
    id: root

    // input adapters: exactly one of each, shared by every screen
    Ipc {}
    Triggers {}
    
    Debug {}

    Lock {}

    ActivateLinux {}

    // services that must exist from the start (their IPC targets), not only once a view shows them
    readonly property var services: [Wallpaper, Notifier]

    // a theme generated from the wallpaper follows it, and the island is the same glass as the
    // windows: Hyprland's window opacity (Config is plain QtQuick and can't ask)
    Binding { target: Config; property: "wallpaperSeed"; value: Wallpaper.seed }
    Binding { target: Config; property: "windowOpacity"; value: Desktops.windowOpacity }

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
