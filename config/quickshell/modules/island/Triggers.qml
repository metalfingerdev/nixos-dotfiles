import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.services

// System events -> alerts. Knows nothing about priority, timing or queueing: the machine decides.
Scope {
    id: root

    // ---- config ----
    property bool followFocus: true      // the idle island moves to the monitor Hyprland focuses
    property bool mediaToasts: true      // a track starting (or playback starting) shows the media card
    property bool switcherToasts: true   // switching workspace shows the dots (views/Switcher.qml)

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

    // ---- the focused monitor: an idle island follows it (an open one stays where it is) ----
    Connections {
        target: Hyprland
        enabled: root.followFocus
        function onFocusedMonitorChanged() {
            const name = Hyprland.focusedMonitor?.name
            if (name && (Engine.hidden || Engine.phase === "rest")) Engine.setScreen(name)
        }
    }

    // ---- workspaces: GNOME-style dots when the focused workspace changes. Not while a view that
    // shows workspaces itself is open (Tabs, the overview), nor over the glance under the pointer.
    // Priority 1 and queue: false (Registry), so it never interrupts anything and is never kept. ----
    Connections {
        target: Hyprland
        enabled: root.switcherToasts
        function onFocusedWorkspaceChanged() {
            const id = Hyprland.focusedWorkspace?.id ?? -1
            if (id <= 0 || Engine.phase === "peek") return
            if (Engine.view === Engine.View.Tabs || Engine.view === Engine.View.Workspaces) return
            root.alert(Engine.View.Switcher)
        }
    }

    // ---- media: a new track, or playback starting. A quiet toast: it never interrupts an open
    // view (priority 1 is the lowest a pinned view has) and isn't kept for later. ----
    Connections {
        target: Players
        enabled: root.mediaToasts
        function onTrackChanged()   { root.media() }
        function onPlayingChanged() { if (Players.playing) root.media() }
    }
    function media() {
        if (armed && Players.playing && (Players.active?.trackTitle ?? "") !== "" && Engine.view !== Engine.View.Media)
            Engine.alert(Engine.View.Media, 1)
    }

    // ---- battery: the charger coming or going, and running low (critical: nearly empty) ----
    Connections {
        target: Energy
        function onPluggedChanged() { if (Energy.present) root.alert(Engine.View.Battery) }
        function onWarn(critical) {
            const v = Engine.View.Battery
            Engine.alert(v, Registry.priority(v, critical))         // a warning skips the startup guard
        }
    }

    // ---- notifications: one view. As a toast it shows the popups, and lives exactly as long as
    // there are any; pinned it is the center. ----
    readonly property bool notifications: Engine.view === Engine.View.Notifications
    readonly property bool popupShown: notifications && Engine.phase === "toast"
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