import QtQuick
import Quickshell
import qs.modules.island

ShellRoot {
    id: root

    // input adapters: exactly one of each, shared by every screen
    Ipc {}
    Triggers {}
    Debug {}        // live snapshot overlay, hidden until `qs ipc call island debug true`

    // one Bar per screen; only the one on Engine.activeScreen shows the island
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
