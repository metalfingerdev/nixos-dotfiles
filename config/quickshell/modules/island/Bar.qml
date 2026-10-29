import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

import qs.modules.island
import qs.modules.components
import qs.modules.services

//   Loader item ──implicit size──► proxy (invisible, snaps instantly, the truth)
//                                    └──► sx/sy/sw/sh (eased) ──► surface (visible)
//
// One Bar exists per screen (see shell.qml). All Bars share the Engine, but only the one on
// Engine.activeScreen draws the island; the others only keep their top-edge hot zone.
//
// The look comes from Config (views/Settings.qml, views/Theme.qml):
//   style "pill"   floats `gap` below the top edge, every corner round
//         "notch"  flush with the top edge, square top, anti-corners curving into the screen edge
//   handle "strip" while auto-hide has hidden the island, a thin bar stays at the top edge
// The glass is Hyprland's: the overlay's namespace is glass:island, which hypr/modules/look.lua's `glass`
// layer rule blurs, and the surface takes the windows' opacity (Config.island).
// Any shape lower than twice Config.radius is a capsule (the compact clock, the volume HUD).
Scope {
    id: root

    // set by Variants
    required property var modelData
    readonly property var screen: modelData
    readonly property bool active: Engine.activeScreen === screen.name

    readonly property bool notch: Config.style === "notch"
    readonly property real gap: notch ? 0 : 8      // distance from the top edge
    readonly property real edgePad: 8              // keep the island this far from the screen sides
    readonly property real hotZone: 4              // auto-hide: height of the top-edge strip that reveals the island
    readonly property bool debug: Engine.debug     // show the proxy as a faint green box (watch it snap)
    readonly property int space: gap + Math.ceil(36 * Config.scale)   // height reserved at the top when auto-hide is off

    // auto-hide's handle: what stays of the island while it is hidden
    readonly property bool strip: Engine.hidden && Config.handle === "strip"
    readonly property real stripW: 96
    readonly property real stripH: 5

    // Morph feel: Config.curve / motionMs (Motion), the same as Hyprland's windows. A redirect
    // mid-flight starts a new ease from wherever the island is, dropping the speed it had.

    // false: view is final-size, top-aligned and horizontally centred in the surface
    // true:  view is final-size AND sits at its final screen position; the surface slides over it
    readonly property bool pinView: false

    // view swap: `target` is what we want, `shown` is what is actually loaded
    readonly property int target: Engine.view
    property int shown: -1
    onTargetChanged: swap.restart()

    // The x the shown view is centred on (Engine.anchorX, -1 = screen centre). Opening a view moves
    // Engine.anchorX at once, but the island only follows once swap has loaded that view, so it moves
    // in one go. Sliding off at the old size first put the load (it blocks) and the new size's
    // redirect in the middle of the slide: a visible stutter.
    property real anchor: -1
    Connections {
        target: Engine
        // the snapshot, not Engine.view: that binding may not have caught up yet
        function onAnchorXChanged() { if (Engine.snapshot.view === root.shown) root.anchor = Engine.anchorX }
    }

    // ---- animated rect, in window coords. Only snap() writes these. ----
    // The Behaviors are off until `armed`, so the startup layout (window going 0 -> real size) and
    // the moment this Bar becomes the active one snap into place instead of sliding in.
    property real sx: 0
    property real sy: 0
    property real sw: 0
    property real sh: 0

    Behavior on sx { enabled: root.armed; Motion {} }
    Behavior on sy { enabled: root.armed; Motion {} }
    Behavior on sw { enabled: root.armed; Motion {} }
    Behavior on sh { enabled: root.armed; Motion {} }

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
    // Copy the proxy rect into the animated rect. Armed, each assignment starts (or redirects) an
    // animation; disarmed, the Behaviors are off and it jumps. Called (coalesced) whenever the proxy
    // moves or resizes.
    function snap() {
        sx = proxy.x; sy = proxy.y
        sw = proxy.width; sh = proxy.height
    }

    // A click on the island itself (not on a control in the view): a toast opens its full view (the
    // Registry's `opens`: the workspace dots open the overview) or stops timing out (its own view
    // is pinned); the clock (Compact) and the hub's peek open the hub, Tabs, pinned. Elsewhere it
    // does nothing.
    function pinShown() {
        const x = Engine.anchorX >= 0 ? Engine.anchorX : undefined
        if (Engine.phase === "toast") Engine.open(Registry.get(Engine.view)?.opens ?? Engine.view, x)
        else if (Engine.phase === "rest" || Engine.phase === "peek") Engine.open(Engine.View.Tabs)
    }

    // fade out -> load the new view (island starts resizing) -> fade in
    SequentialAnimation {
        id: swap
        NumberAnimation { target: loader; property: "opacity"; to: 0; duration: root.shown === -1 ? 0 : 90 }
        ScriptAction    { script: { root.anchor = Engine.anchorX; root.shown = root.target } }
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

    // Full-screen overlay. Input: only the island's FINAL rect, or the whole screen while a view
    // is pinned (a click outside closes it), or nothing while hidden (the handle is only a hint;
    // the hot zone above reveals). Exists on the active screen only.
    PanelWindow {
        id: overlay

        screen: root.screen
        visible: root.active
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { item: Engine.hidden ? null : Engine.pinned ? outside : proxy }

        WlrLayershell.namespace: "glass:island"     // Hyprland's glass (hypr/modules/look.lua)
        WlrLayershell.layer: WlrLayer.Top
        // Pinned views and the peek view (hover) get the keyboard (the user is here).
        // Rest and Toast never take it, so a toast can't steal typing from an app.
        WlrLayershell.keyboardFocus: root.active && Engine.keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Whether this window really has the keyboard (Hyprland sent it), not only asked for it.
        // Engine.closeThen waits for it to go before it moves Hyprland's focus.
        Item {
            readonly property bool has: Window.active
            onHasChanged: Engine.hasKeyboard = has
        }

        // a click anywhere outside a pinned view closes it; the mouse's back button goes back
        MouseArea {
            id: outside
            anchors.fill: parent
            enabled: Engine.pinned
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => mouse.button === Qt.BackButton ? Engine.back() : Engine.close()
        }

        // HOVER: the pointer is on the island while it is inside the FINAL rect (the proxy, like the
        // input mask), not the moving surface, so what counts as on the island doesn't shift while it
        // animates. On the window's root item, so no control in the view can take the hover from it.
        HoverHandler {
            id: pointer
            // The pointer is back: focus rings hide until the keyboard moves focus again. Only a real
            // move counts: Qt re-sends hover every frame something animates under a still pointer
            // (the morph, a toast), and that used to hide the ring right after every key.
            // The first position after the pointer enters (or the island appears under it) is
            // only the baseline.
            property point last: Qt.point(-1, -1)
            onHoveredChanged: if (!hovered) last = Qt.point(-1, -1)
            onPointChanged: {
                const p = point.position
                if (last.x < 0) { last = Qt.point(p.x, p.y); return }
                if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) < 3) return
                last = Qt.point(p.x, p.y)
                if (Config.focusVisible) Config.focusVisible = false
            }
        }
        readonly property bool onIsland: pointer.hovered
            && pointer.point.position.x >= proxy.x && pointer.point.position.x < proxy.x + proxy.width
            && pointer.point.position.y >= proxy.y && pointer.point.position.y < proxy.y + proxy.height
        onOnIslandChanged: Engine.hover(onIsland)

        // PROXY: invisible. The final size and position, in window coordinates. Never animated.
        Item {
            id: proxy

            // size of the last loaded view, at Config.scale (the island's Size); held while the next
            // one loads, so it never flashes to 0
            property real viewW: 0
            property real viewH: 0

            Binding {
                target: proxy; property: "viewW"
                value: loader.item ? Math.round(loader.item.implicitWidth * Config.scale) : 0
                when: loader.item !== null
                restoreMode: Binding.RestoreNone
            }
            Binding {
                target: proxy; property: "viewH"
                value: loader.item ? Math.round(loader.item.implicitHeight * Config.scale) : 0
                when: loader.item !== null
                restoreMode: Binding.RestoreNone
            }

            width: root.strip ? root.stripW : viewW
            height: root.strip ? root.stripH : viewH
            x: root.abscissa(width, root.anchor)
            y: root.strip ? 0 : Engine.hidden ? -height - root.gap : root.gap

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

        // ANTI-CORNERS (notch): the island curves into the screen edge instead of meeting it at a
        // right angle. Drawn outside the surface (which clips), from the same animated rect.
        // The filled part is the web between the screen edge, the island's side and a curve that
        // bows into that corner: left corner hugs its right side, right corner its left side.
        component AntiCorner: Shape {
            id: corner
            property bool leading: true       // the left one
            readonly property real a: width

            y: root.sy
            width: Math.min(12, root.sh / 2)
            height: width
            visible: root.notch && root.sh > 1
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Config.island
                strokeColor: "transparent"
                startX: 0; startY: corner.leading ? 0 : corner.a
                PathLine { x: corner.leading ? corner.a : 0; y: 0 }
                PathLine { x: corner.a; y: corner.leading ? corner.a : 0 }
                PathQuad {
                    x: 0; y: corner.leading ? 0 : corner.a
                    controlX: corner.leading ? corner.a : 0; controlY: 0
                }
            }
        }
        AntiCorner { leading: true;  x: root.sx - width }
        AntiCorner { leading: false; x: root.sx + root.sw }

        // SURFACE: the visible rectangle, drawn at the animated rect.
        Rectangle {
            id: surface

            readonly property real r: Math.min(height / 2, Config.radius * Config.scale)

            x: root.sx
            y: root.sy
            width: root.sw
            height: root.sh

            topLeftRadius: root.notch ? 0 : r
            topRightRadius: root.notch ? 0 : r
            bottomLeftRadius: r
            bottomRightRadius: r
            color: Config.island
            Behavior on color { ColorAnimation { duration: 200 } }
            clip: true                     // content is revealed, never squished

            // the island's own background: under every control of the view. The mouse's back button
            // goes back from anywhere on the island (no control takes it)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.BackButton
                onClicked: mouse => mouse.button === Qt.BackButton ? Engine.back() : root.pinShown()
            }

            // Hidden behind the handle, the view fades out instead of showing a sliver of itself.
            Item {
                anchors.fill: parent
                opacity: Engine.hidden ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // The view always has its FINAL size (proxy.viewW/H), even while the surface is still smaller.
                // Inactive screens load nothing, so e.g. the launcher's text field exists once, not per monitor.
                // ViewLoader also carries the default keyboard (Tab/arrows/Escape) for every view.
                ViewLoader {
                    id: loader

                    active: root.active
                    onCancel: Engine.close()
                    onBack: Engine.back()
                    onActivity: Engine.key()
                    onNavigated: Config.focusVisible = true

                    // laid out at 100 %, drawn at the island's Size
                    width: proxy.viewW / Config.scale
                    height: proxy.viewH / Config.scale
                    scale: Config.scale
                    transformOrigin: Item.TopLeft

                    x: root.pinView ? proxy.x - surface.x : (surface.width - proxy.viewW) / 2
                    y: root.pinView ? proxy.y - surface.y : 0

                    source: Registry.get(root.shown)?.url ?? ""
                }
            }
        }

        // PRIVACY: a dot beside the island while the microphone (orange) or camera (green) is in
        // use, in every phase. Next to the handle while hidden, smaller.
        Row {
            id: privacy
            readonly property bool small: Engine.hidden
            readonly property int dot: small ? 5 : 8

            visible: Privacy.active
            x: root.sx + root.sw + (root.notch ? 14 : 8)
            y: Math.max(small ? 0 : 4, root.sy + Math.min(root.sh, 36) / 2 - height / 2)
            spacing: small ? 3 : 6

            Repeater {
                model: [
                    { on: Privacy.microphone, color: Config.microphone },
                    { on: Privacy.camera,     color: Config.camera }
                ]

                Item {
                    id: light
                    required property var modelData
                    visible: modelData.on
                    width: privacy.small ? privacy.dot : 16
                    height: width

                    Rectangle {                          // halo
                        anchors.centerIn: parent
                        visible: !privacy.small
                        width: 16; height: 16; radius: 8
                        color: light.modelData.color
                        opacity: 0.2
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: privacy.dot; height: width; radius: width / 2
                        color: light.modelData.color
                    }
                }
            }
        }
    }
}
