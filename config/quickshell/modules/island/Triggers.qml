import QtQuick
import Quickshell
import qs.modules.services

// System events -> alerts. Knows nothing about priority, timing or queueing: the machine decides.
Scope {
    id: root

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