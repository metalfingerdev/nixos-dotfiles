pragma Singleton

import QtQuick
import Quickshell
import "Machine.js" as Machine

// Shell around the pure machine: owns the snapshot and the one Timer. No logic lives here.
QtObject {
    id: root

    enum View {
        Compact,
        Expanded,
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
        Switcher
    }

    // ---- config ----
    readonly property int restView: Engine.View.Compact
    property int peekView: Engine.View.Expanded          // what hovering at rest shows. -1 = off
    property int graceMs: 140          // Peek collapses this long after the pointer leaves
    property int hoverMs: 140          // Peek waits this long before showing (0 = instant)
    property int hideMs: 700           // auto-hide: how long the island lingers at rest before hiding
    property bool debug: false         // Debug overlay + Bar's proxy box. IPC: island debug / toggleDebug
    // What was typed into Expanded's search bar, handed to the launcher it opens (which takes it
    // and clears it). Not machine state: only text in transit between two views.
    property string query: ""

    // ---- state: one immutable snapshot, replaced whole by send() ----
    property var snapshot: Machine.initial(restView, true)

    // ---- read-only views of it ----
    readonly property bool   autoHide: snapshot.autoHide
    readonly property bool   hidden:   snapshot.phase === Machine.Phase.Hidden
    readonly property string phase:   snapshot.phase
    readonly property int    view:    snapshot.view
    readonly property bool   hovered: snapshot.hovered
    readonly property bool   peeking: snapshot.peeking   // the peek key is down (or toggled on)
    readonly property real   anchorX: snapshot.x      // window x to centre on, -1 = screen centre
    readonly property bool   pinned:  snapshot.phase === Machine.Phase.Pinned
    // the island takes the keyboard: a pinned view, or the peek view (hovered)
    readonly property bool   keyboard: pinned || snapshot.phase === Machine.Phase.Peek

    // ---- which screen shows the island (the machine knows nothing about screens) ----
    property string screenName: ""                    // "" = the first screen
    readonly property string activeScreen: resolveScreen(screenName)

    function hasScreen(name) {
        const list = Quickshell.screens
        for (let i = 0; i < list.length; i++) if (list[i].name === name) return true
        return false
    }
    // a screen that was unplugged falls back to the first one
    function resolveScreen(name) {
        if (hasScreen(name)) return name
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }
    function screens() {
        const out = []
        for (let i = 0; i < Quickshell.screens.length; i++) out.push(Quickshell.screens[i].name)
        return out
    }
    function setScreen(name) {
        if (!hasScreen(name) || name === activeScreen) return
        screenName = name
        send({ type: Machine.Event.Leave })           // the old surface is gone: nothing is hovered any more
    }

    // ---- public API: one function, one event ----
    function open(v, x)    { send({ type: Machine.Event.Open, view: v, x: x }) }
    function close()       { send({ type: Machine.Event.Close }) }
    function back()        { send({ type: Machine.Event.Back }) }
    // priority: optional, this alert's own (e.g. a critical notification); omitted = the Registry's
    function alert(v, priority) { send({ type: Machine.Event.Alert, view: v, priority: priority }) }
    // Reaching a screen's top edge while the island is idle moves it there; otherwise it stays put.
    function edge(on, name) {
        const idle = phase === Machine.Phase.Hidden || phase === Machine.Phase.Rest
        if (on && name !== undefined && idle) setScreen(name)
        send({ type: on ? Machine.Event.Reach : Machine.Event.Retreat })
    }
    function setAutoHide(on)   { send({ type: Machine.Event.Mode, on: on }) }
    function hover(on)     { send({ type: on ? Machine.Event.Hover : Machine.Event.Leave }) }
    function peek(on)      { send({ type: on ? Machine.Event.Peek : Machine.Event.Unpeek }) }  // the peek key: the rest view while held
    // The peek key as one binding: press to show, press again to hide. Reads the snapshot, so it never
    // gets out of step: anything that clears `peeking` (a hover peek, a view opening) resets it too.
    function togglePeek()  { peek(!peeking) }
    function key()         { send({ type: Machine.Event.Key }) }     // any keystroke in the island

    // ---- the shell ----
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