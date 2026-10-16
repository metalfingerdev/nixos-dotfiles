pragma Singleton

import QtQuick

// A small statechart.
//   control state : phase  (Collapsed | Peek | Pinned | Transient)
//   extended state: view, hovered, engaged
//   config        : mode, space, compactWidget      (never changed by send())
// One transition function (send), one handler per phase, and every entry action
// (stop old timers, start the new one) lives in enter(). Timers only ever send Expire.
QtObject {
    id: root

    enum Phase  { Collapsed, Peek, Pinned, Transient }
    enum View   { Idle, Media, Notify, Compact, Dashboard, Volume, Brightness, Theme, Bluetooth, Launcher, Workspaces }
    enum Event  { HoverIn, HoverOut, Click, Outside, Escape, Open, Back, Alert, Expire, Close, Engage, Release }
    enum Mode   { Pill, Notch }
    enum Widget { Clock, Date }

    // ---- control + extended state ----
    property int phase: IslandState.Phase.Collapsed
    property int view: IslandState.View.Idle
    property int pendingView: -1
    property bool hovered: false                      // tracked in every phase
    property bool engaged: false                      // the current view says "the user is working in me" (keyboard etc.)

    // ---- config ----
    property int mode: IslandState.Mode.Notch
    property bool space: true                        // reserve screen space; rest shows the default view instead of the handle
    property int compactWidget: IslandState.Widget.Clock   // the default view's content
    readonly property int compactHeight: 28
    readonly property int settleMs: 2000          // Back -> Idle stays open this long, hover or not

    readonly property bool pinned: phase === IslandState.Phase.Pinned
    readonly property bool holding: hovered || engaged                 // either one pauses the state timer
    readonly property bool keyboard: pinned && Registry.wantsKeys(view) // the surface must own the keyboard
    readonly property var phaseNames: ["collapsed", "peek", "pinned", "transient"]

    // What hovering shows: reserved space already shows the default view, so hover opens Idle;
    // otherwise (handle at rest) hover reveals the default view.
    function peekView() { return space ? IslandState.View.Idle : IslandState.View.Compact }

    // ---- the one entry point -------------------------------------------------
    function send(event, view) {
        const E = IslandState.Event
        switch (event) {
        case E.HoverIn:  hovered = true; graceTimer.stop(); break
        case E.HoverOut: hovered = false; break
        case E.Engage:   return engage(true)
        case E.Release:  return engage(false)
        }

        switch (phase) {
        case IslandState.Phase.Collapsed: return whenCollapsed(event, view)
        case IslandState.Phase.Peek:      return whenPeek(event, view)
        case IslandState.Phase.Transient: return whenTransient(event, view)
        case IslandState.Phase.Pinned:    return whenPinned(event, view)
        }
    }

    // ---- transition table: one function per phase ----------------------------
    function whenCollapsed(event, v) {
        const E = IslandState.Event
        switch (event) {
        case E.HoverIn: return enter(IslandState.Phase.Peek, peekView())
        case E.Click:   return openHome()
        case E.Open:    return open(v)
        case E.Alert:   return alert(v)
        }
    }

    function whenPeek(event, v) {
        const E = IslandState.Event
        switch (event) {
        case E.HoverOut: return graceTimer.restart()            // collapse after a short grace
        case E.Click:    return space ? close() : openHome()     // click the surface -> Idle, pinned
        case E.Open:     return open(v)
        case E.Alert:    return alert(v)
        case E.Close:    return close()
        }
    }

    function whenTransient(event, v) {
        const E = IslandState.Event
        switch (event) {
        case E.Expire:   return rest()
        case E.HoverIn:  return stateTimer.stop()               // pause while the pointer is on it
        case E.HoverOut: return resumeStateTimer()
        case E.Back:     return settle()
        case E.Click:    return close()
        case E.Open:     return open(v)
        case E.Alert:    if (Registry.priority(v) >= Registry.priority(root.view)) alert(v); return
        case E.Outside:
        case E.Escape:
        case E.Close:    return close()
        }
    }

    function whenPinned(event, v) {
        const E = IslandState.Event
        switch (event) {
        case E.HoverIn:  return stateTimer.stop()          // Rule 1
        case E.HoverOut: return resumeStateTimer()         // Rule 1
        case E.Alert:    return deferAlert(v)              // Rule 3
        case E.Open:     return v === root.view ? close() : open(v)
        case E.Back:     return settle()
        case E.Expire:   return rest()
        case E.Click:
        case E.Outside:
        case E.Escape:
        case E.Close:    return close()
        }
    }

    // ---- actions ----------------------------------------------------------------
    function openHome() { return open(IslandState.View.Idle) }

    // pin a view; it may carry its own timeout (Registry), 0 = stays until closed
    function open(v) {
        if (Registry.get(v)) enter(IslandState.Phase.Pinned, v, Registry.timeout(v))
    }

    function settle() { enter(IslandState.Phase.Pinned, IslandState.View.Idle, settleMs, true) }   // Rule 2

    function alert(v) {
        const e = Registry.get(v)
        if (e && e.hold > 0)
            enter(IslandState.Phase.Transient, v, e.hold)
    }

    function deferAlert(v) {
        if (Registry.defers(v) && Registry.priority(v) >= Registry.priority(pendingView))
            pendingView = v
    }

    function flushPending() {
        if (pendingView === -1) return false
        const v = pendingView
        pendingView = -1
        alert(v)
        return true
    }

    function enter(newPhase, newView, ms, ignoreHover) {
        graceTimer.stop()
        stateTimer.stop()
        // engagement belongs to the view that reported it; a new view starts clean
        if (newPhase === IslandState.Phase.Collapsed || (newView !== undefined && newView !== view))
            engaged = false
        if (newView !== undefined) view = newView
        phase = newPhase

        stateMs = ms || 0
        stateTimer.interval = Math.max(stateMs, 1)

        const timed = newPhase === IslandState.Phase.Transient || newPhase === IslandState.Phase.Pinned
        const waits = timed && !ignoreHover && holding
        if (stateMs > 0 && !waits) stateTimer.start()
    }

    // manual close: straight to rest, even if the pointer is still over the island
    function close() { if (!flushPending()) enter(IslandState.Phase.Collapsed) }

    // automatic close (timer): hover-aware
    function rest() {
        if (flushPending()) return
        enter(hovered ? IslandState.Phase.Peek : IslandState.Phase.Collapsed,
              hovered ? peekView() : undefined)
    }

    // ---- entry action: the only place that changes phase ------------------------
    property int stateMs: 0

    // Pointer-independent twin of hover (Rule 1). Only timed phases have a timer to pause.
    function engage(on) {
        if (engaged === on) return
        const timed = phase === IslandState.Phase.Pinned || phase === IslandState.Phase.Transient
        engaged = on && timed
        if (!timed) return
        if (engaged) stateTimer.stop()
        else         resumeStateTimer()
    }

    function resumeStateTimer() { if (stateMs > 0 && !holding) stateTimer.restart() }

    // ---- timers -----------------------------------------------------------------
    property Timer graceTimer: Timer {          // hover debounce
        interval: 140
        onTriggered: if (root.phase === IslandState.Phase.Peek && !root.hovered)
                         root.enter(IslandState.Phase.Collapsed)
    }

    property Timer stateTimer: Timer {          // "after(ms) -> Expire" for the current state
        onTriggered: root.send(IslandState.Event.Expire)
    }
}