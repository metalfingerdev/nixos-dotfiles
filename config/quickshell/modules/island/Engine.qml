pragma Singleton

import QtQuick
import Quickshell
import "Machine.js" as Machine

// Shell around the pure machine, which is what makes it testable: it owns the snapshot and its Timer.
// No logic lives here, apart from closeThen().
QtObject {
    id: root

    enum View {
        Compact,
        Network,
        Launcher,
        Bluetooth,
        Volume,
        Brightness,
        Notifications,
        Media,
        Battery,
        Clock,
        Power,
        Theme,
        Workspaces,
        Tabs,
        Dashboard,
        Switcher,
        Mixer,
        Settings,
        Colours,
        Wallpapers,
        Expanded
    }

    readonly property int restView: Engine.View.Compact
    property int peekView: Engine.View.Expanded          // what hovering the island at rest shows. -1 = off
    property int graceMs: 140
    property int hoverMs: 140
    property int hideMs: 700
    property bool debug: false

    property var snapshot: Machine.initial(restView, true)

    readonly property bool   autoHide: snapshot.autoHide
    readonly property bool   hidden:   snapshot.phase === Machine.Phase.Hidden
    readonly property string phase:   snapshot.phase
    readonly property int    view:    snapshot.view
    readonly property bool   hovered: snapshot.hovered
    readonly property real   anchorX: snapshot.x      // window x to centre on, -1 = screen centre
    readonly property bool   pinned:  snapshot.phase === Machine.Phase.Pinned
    readonly property bool   toast:   snapshot.phase === Machine.Phase.Toast
    readonly property bool   peeked:  snapshot.phase === Machine.Phase.Peek
    readonly property bool   atRest:  snapshot.phase === Machine.Phase.Rest
    readonly property bool   idle:    hidden || atRest

    property string screenName: ""
    // a screen that was unplugged falls back to the first one
    readonly property var screen: Array.from(Quickshell.screens).find(s => s.name === screenName) ?? Quickshell.screens[0] ?? null
    readonly property string activeScreen: screen?.name ?? ""

    function screens() { return Array.from(Quickshell.screens, s => s.name) }
    function setScreen(name) {
        if (!screens().includes(name) || name === activeScreen) return
        screenName = name
        send({ type: Machine.Event.Leave })           // the old surface is gone: nothing is hovered any more
    }

    function open(v, x)    { send({ type: Machine.Event.Open, view: v, x: x }) }
    function close()       { send({ type: Machine.Event.Close }) }
    function back()        { send({ type: Machine.Event.Back }) }
    function alert(v, priority) { send({ type: Machine.Event.Alert, view: v, priority: priority }) }
    // Reaching a screen's top edge while the island is idle moves it there; otherwise it stays put.
    function edge(on, name) {
        if (on && name !== undefined && idle) setScreen(name)
        send({ type: on ? Machine.Event.Reach : Machine.Event.Retreat })
    }
    function setAutoHide(on)   { send({ type: Machine.Event.Mode, on: on }) }
    function hover(on)     { send({ type: on ? Machine.Event.Hover : Machine.Event.Leave }) }
    function peek(on)      { send({ type: on ? Machine.Event.Peek : Machine.Event.Unpeek }) }
    // The peek key as one binding: press to show, press again to hide. Reads the snapshot, so it never
    // gets out of step: anything that clears `peeking` (a hover peek, a view opening) resets it too.
    function togglePeek()  { peek(!snapshot.peeking) }
    function key()         { send({ type: Machine.Event.Key }) }

    // While the island holds the keyboard (an exclusive layer), Hyprland refuses to focus any window,
    // so the window it thinks is focused goes stale. When the island lets go, Hyprland focuses that
    // window again and goes back to its workspace (or reopens its special workspace), undoing a
    // switch made in the meantime. So an action that moves Hyprland's focus comes after the release:
    // closeThen(action) closes the island and runs `action` once Bar reports the keyboard gone
    // (hasKeyboard), or after releaseMs if that never comes.
    property bool hasKeyboard: false   // Bar: the island's window has the keyboard right now
    property int releaseMs: 200
    property var afterRelease: []
    function closeThen(action) {
        const waits = pinned || hasKeyboard
        close()
        if (!waits) { action(); return }
        afterRelease.push(action)
        released.restart()
    }
    function runReleased() {
        released.stop()
        const run = afterRelease
        afterRelease = []
        for (const action of run) action()
    }
    onHasKeyboardChanged: if (!hasKeyboard) runReleased()
    property Timer released: Timer {
        interval: root.releaseMs
        onTriggered: root.runReleased()
    }

    function config() {
        return { restView: restView, peekView: peekView, graceMs: graceMs, hoverMs: hoverMs, hideMs: hideMs,
                 known:   v => Registry.get(v) !== null,
                 priority: v => Registry.priority(v),
                 queues:   v => Registry.queues(v),
                 timeout: v => Registry.timeout(v) }
    }

    function send(event) {
        const prev = snapshot
        const next = Machine.reduce(prev, event, config())
        snapshot = next
        if (next.timer !== prev.timer) arm(next.timer)
    }

    function arm(t) {
        clock.stop()
        if (t) { clock.interval = t.ms; clock.start() }
    }

    property Timer clock: Timer {
        onTriggered: root.send({ type: Machine.Event.Expire })
    }
}