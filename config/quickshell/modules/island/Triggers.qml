import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.services

// System events -> alerts. Knows nothing about priority, timing or queueing: the machine decides.
Scope {
    id: root

    property bool followFocus: true
    property bool switcherToasts: true

    // services report their initial values at startup; don't toast those
    property bool armed: false
    Timer { interval: 2000; running: true; onTriggered: root.armed = true }

    function alert(view) { if (armed) Engine.alert(view) }

    Connections {
        target: Audio
        function onVolumeChanged() { root.alert(Engine.View.Volume) }
        function onMutedChanged()  { root.alert(Engine.View.Volume) }
    }

    Connections {
        target: Backlight
        function onPercentChanged() { root.alert(Engine.View.Brightness) }
    }

    Connections {
        target: Hyprland
        enabled: root.followFocus
        function onFocusedMonitorChanged() {
            const name = Hyprland.focusedMonitor?.name
            if (name && Engine.idle) Engine.setScreen(name)
        }
    }

    // Priority 1 and queue: false (Registry), so it never interrupts a view and is never kept. Not over
    // Expanded either: at Peek any alert would replace it under the pointer.
    Connections {
        target: Hyprland
        enabled: root.switcherToasts
        function onFocusedWorkspaceChanged() {
            const id = Hyprland.focusedWorkspace?.id ?? -1
            if (id > 0 && !Engine.peeked) root.alert(Engine.View.Switcher)
        }
    }

    Connections {
        target: Energy
        function onPluggedChanged() { if (Energy.present) root.alert(Engine.View.Battery) }
        function onWarn(critical) {
            const v = Engine.View.Battery
            Engine.alert(v, Registry.priority(v, critical))         // a warning skips the startup guard
        }
    }

    // As a toast the view lives exactly as long as there are popups; pinned it is the center.
    readonly property bool notifications: Engine.view === Engine.View.Notifications
    readonly property bool popupShown: notifications && Engine.toast
    readonly property bool centerShown: notifications && Engine.pinned

    // Popups count down only while on screen and not under the pointer.
    Binding { target: Notifier; property: "held"; value: !root.popupShown || Engine.hovered }

    // Called later, never from inside Engine.send(): the center has seen everything, so nothing
    // is left to pop up; an emptied (or delivered-but-already-empty) popup view closes.
    function settle() {
        if (centerShown) Notifier.closeAll()
        else if (popupShown && Notifier.popups.length === 0) Engine.close()
    }

    // Notifications skip the startup guard: one arriving in the first 2 s should show.
    Connections {
        target: Notifier
        function onReceived(critical) {
            const v = Engine.View.Notifications
            if (!root.centerShown) Engine.alert(v, Registry.priority(v, critical))
        }
        function onPopupsChanged() { Qt.callLater(root.settle) }
    }

    Connections {
        target: Engine
        function onViewChanged()  { Qt.callLater(root.settle) }
        function onPhaseChanged() { Qt.callLater(root.settle) }     // popups -> center keeps the view
    }
}