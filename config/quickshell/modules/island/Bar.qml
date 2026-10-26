import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.modules.island

//   Loader item ──implicit size──► proxy (invisible, snaps instantly, the truth)
//                                    └──► sx/sy/sw/sh (springs) ──► surface (visible)
//
// One Bar exists per screen (see shell.qml). All Bars share the Engine, but only the one on
// Engine.activeScreen draws the island; the others only keep their top-edge hot zone.
Scope {
    id: root

    // set by Variants
    required property var modelData
    readonly property var screen: modelData
    readonly property bool active: Engine.activeScreen === screen.name

    readonly property real gap: 8          // distance from the top edge
    readonly property real edgePad: 8      // keep the island this far from the screen sides
    readonly property real hotZone: 4      // auto-hide: height of the top-edge strip that reveals the island
    readonly property bool debug: Engine.debug   // show the proxy as a faint green box (watch it snap)
    readonly property int space: 42        // height reserved at the top when auto-hide is off

    // Morph feel (SpringAnimation). Higher stiffness = snappier; lower damping = more overshoot.
    // A redirect mid-flight keeps the current velocity, so the island never lurches.
    readonly property real stiffness: 3.2
    readonly property real damping: 0.34

    // false: view is final-size, top-aligned and horizontally centred in the surface
    // true:  view is final-size AND sits at its final screen position; the surface slides over it
    readonly property bool pinView: false

    // view swap: `target` is what we want, `shown` is what is actually loaded
    readonly property int target: Engine.view
    property int shown: -1
    onTargetChanged: swap.restart()

    // ---- sprung rect, in window coords. Only snap() writes these. ----
    // The Behaviors are off until `armed`, so the startup layout (window going 0 -> real size) and
    // the moment this Bar becomes the active one snap into place instead of sliding in.
    property real sx: 0
    property real sy: 0
    property real sw: 0
    property real sh: 0

    Behavior on sx { enabled: root.armed; SpringAnimation { spring: root.stiffness; damping: root.damping; epsilon: 0.25 } }
    Behavior on sy { enabled: root.armed; SpringAnimation { spring: root.stiffness; damping: root.damping; epsilon: 0.25 } }
    Behavior on sw { enabled: root.armed; SpringAnimation { spring: root.stiffness; damping: root.damping; epsilon: 0.25 } }
    Behavior on sh { enabled: root.armed; SpringAnimation { spring: root.stiffness; damping: root.damping; epsilon: 0.25 } }

    property bool armed: false
    Timer { id: armTimer; onTriggered: root.armed = true }
    function disarm(ms) { armed = false; armTimer.interval = ms; armTimer.restart() }

    onActiveChanged: { if (active) disarm(150); else armed = false }

    // Island's left edge: centred on `center` (the pointer), or on the screen when center < 0.
    // Clamped against the FINAL width, so it is right on the first frame.
    function abscissa(w, center) {
        const c = center >= 0 ? center : overlay.width / 2
        return Math.round(Math.max(edgePad, Math.min(overlay.width - w - edgePad, c - w / 2)))
    }
    // Copy the proxy rect into the sprung rect. Armed, each assignment starts (or redirects) a
    // spring; disarmed, the Behaviors are off and it jumps. Called (coalesced) whenever the proxy
    // moves or resizes.
    function snap() {
        sx = proxy.x; sy = proxy.y
        sw = proxy.width; sh = proxy.height
    }

    // fade out -> load the new view (island starts resizing) -> fade in
    SequentialAnimation {
        id: swap
        NumberAnimation { target: loader; property: "opacity"; to: 0; duration: root.shown === -1 ? 0 : 90 }
        ScriptAction    { script: root.shown = root.target }
        NumberAnimation { target: loader; property: "opacity"; to: 1; duration: 140 }
    }

    Component.onCompleted: { snap(); swap.start(); disarm(500) }

    // Top strip. Auto-hide off: reserves screen space on the active screen only, fully click-through.
    // Auto-hide on: a thin hot zone on EVERY screen; reaching it reveals the island (on that screen).
    PanelWindow {
        id: spacer

        screen: root.screen
        visible: root.active || Engine.autoHide
        anchors { top: true; left: true; right: true }
        implicitHeight: Engine.autoHide ? root.hotZone : root.space
        exclusionMode: Engine.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto
        color: "transparent"
        mask: Region { item: Engine.autoHide ? edge : null }

        Item {
            id: edge
            anchors.fill: parent
            HoverHandler { onHoveredChanged: Engine.edge(hovered, root.screen.name) }
        }
    }

    // Full-screen overlay; only the island's FINAL rect is clickable. Exists on the active screen only.
    PanelWindow {
        id: overlay

        screen: root.screen
        visible: root.active
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: proxy }

        WlrLayershell.layer: WlrLayer.Top
        // Pinned views and the peek view (hover) get the keyboard (the user is here).
        // Rest and Toast never take it, so a toast can't steal typing from an app.
        WlrLayershell.keyboardFocus: root.active && Engine.keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // PROXY: invisible. The final size and position, in window coordinates. Never animated.
        Item {
            id: proxy

            // size of the last loaded view; held while the next one loads, so it never flashes to 0
            property real viewW: 0
            property real viewH: 0

            Binding {
                target: proxy; property: "viewW"
                value: loader.item ? loader.item.implicitWidth : 0
                when: loader.item !== null
                restoreMode: Binding.RestoreNone
            }
            Binding {
                target: proxy; property: "viewH"
                value: loader.item ? loader.item.implicitHeight : 0
                when: loader.item !== null
                restoreMode: Binding.RestoreNone
            }

            width: viewW
            height: viewH
            x: root.abscissa(width, Engine.anchorX)
            y: Engine.hidden ? -height - root.gap : root.gap

            // callLater coalesces the burst of x/y/w/h changes into one snap
            onXChanged:      Qt.callLater(root.snap)
            onYChanged:      Qt.callLater(root.snap)
            onWidthChanged:  Qt.callLater(root.snap)
            onHeightChanged: Qt.callLater(root.snap)

            Rectangle {
                anchors.fill: parent
                visible: root.debug
                color: '#338aff30'           // translucent green
            }
        }

        // SURFACE: the visible rectangle, drawn at the sprung rect.
        Rectangle {
            id: surface

            x: root.sx
            y: root.sy
            width: Math.max(0, root.sw)      // a spring can undershoot; never go negative
            height: Math.max(0, root.sh)

            radius: 12
            color: "#101014"
            clip: true                     // content is revealed, never squished

            HoverHandler { onHoveredChanged: Engine.hover(hovered) }

            // The view always has its FINAL size (proxy.viewW/H), even while the surface is still smaller.
            // Inactive screens load nothing, so e.g. the launcher's text field exists once, not per monitor.
            // ViewLoader also carries the default keyboard (Tab/arrows/Escape) for every view.
            ViewLoader {
                id: loader

                active: root.active
                onCancel: Engine.back()
                onActivity: Engine.key()

                width: proxy.viewW
                height: proxy.viewH

                x: root.pinView ? proxy.x - surface.x : (surface.width - width) / 2
                y: root.pinView ? proxy.y - surface.y : 0

                source: Registry.get(root.shown)?.url ?? ""
            }
        }
    }
}
