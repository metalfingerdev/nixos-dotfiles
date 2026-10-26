.pragma library

// Pure statechart: no QML, no timers, no clock, no globals.
//   reduce(state, event, cfg) -> state
// States are plain objects and are never mutated. The timer is part of the state:
// the shell arms its one real Timer whenever state.timer changes identity.
//
//   state { phase, view, prio, hovered, edge, peeking, x, ms, timer, history, autoHide, queued, queuedPrio }
//   prio  priority of what is showing: the alert's own, else cfg.priority(view). Kept in history and
//         in the queue, so an urgent alert stays urgent wherever it goes
//   peeking  the peek key is held (IPC `peek true` until `peek false`). Only ever true at Rest
//   timer { ms, kind } | null   kind: "hold" (phase countdown) | "intent" (hover) | "grace" (peek)
//   x     anchor in window coords: the x to centre on, -1 = the screen centre
//   event { type, view?, x?, on?, priority? }   priority: alerts only; omitted = cfg.priority(view)
//   cfg   { restView, peekView, hubView, graceMs, hoverMs, hideMs,
//           known(view), timeout(view), priority(view), queues(view) }
//
//   Hidden  island parked off-screen (auto-hide mode only); the top-edge hot zone reveals it
//   Rest    restView; in auto-hide mode it lingers hideMs, then goes back to Hidden. The peek key
//           shows it while held: releasing it hides at once (auto-hide), not after the linger
//   Peek    peekView shown because of hover; no countdown
//   Pinned  an opened view; counts down by its Registry timeout unless held, each keystroke restarts it.
//           A service view (anything but the rest, peek and hub views) whose countdown ends, or that is
//           backed out of with nothing behind it, goes to the hub (Tabs) first; the hub then counts
//           down to Rest. The peek view (Expanded) is where you come in, so it is never in the history.
//   Toast   a view the system triggered (volume, notification...); same countdown as Pinned

var Phase = { Hidden: "hidden", Rest: "rest", Peek: "peek", Pinned: "pinned", Toast: "toast" }
var Event = { Hover: "hover", Leave: "leave", Reach: "reach", Retreat: "retreat", Mode: "mode",
              Peek: "peek", Unpeek: "unpeek",
              Open: "open", Close: "close", Back: "back", Alert: "alert", Key: "key", Expire: "expire" }

function initial(restView, autoHide) {
    return { phase: autoHide ? Phase.Hidden : Phase.Rest, view: restView, prio: 0,
             hovered: false, edge: false, peeking: false, x: -1, ms: 0, timer: null,
             history: [], autoHide: !!autoHide, queued: -1, queuedPrio: -1 }
}

// ---- atoms -------------------------------------------------------------------
function set(s, patch) { return Object.assign({}, s, patch) }
function timed(s)      { return s.phase === Phase.Pinned || s.phase === Phase.Rest || s.phase === Phase.Toast }
// The pointer is on the island or in the top-edge hot zone, or the peek key is held: countdowns pause.
function holding(s)    { return s.hovered || s.edge || s.peeking }
// An event's priority: its own if it brought one, else the view's.
function prio(e, cfg)  { return e.priority !== undefined ? e.priority : cfg.priority(e.view) }
// What a history entry remembers about the current view, so Back restores it exactly.
function here(s)       { return { view: s.view, x: s.x, priority: s.prio } }

// The only rule about timers: a timed phase, with a duration, that nobody is holding.
function wanted(s)     { return timed(s) && s.ms > 0 && !holding(s) ? { ms: s.ms, kind: "hold" } : null }

// start: always a NEW timer object, so the shell restarts its Timer. Used when a phase is entered
// (a refreshed toast must count down from the top again) and on every keystroke.
function start(s)      { return set(s, { timer: wanted(s) }) }

// rearm: re-apply the rule after a "holding" fact may have changed. If the countdown that is
// already running is the one we still want, keep that very object: the shell sees no change and
// leaves its Timer alone. Kind is compared too, so a hover-intent or grace timer is never mistaken
// for the phase countdown just because the durations happen to match.
function rearm(s) {
    const w = wanted(s), t = s.timer
    return w && t && t.kind === w.kind && t.ms === w.ms ? s : set(s, { timer: w })
}

// How long Rest lingers: only in auto-hide mode.
function restMs(s, cfg) { return s.autoHide ? cfg.hideMs : 0 }

// The history an open() leaves behind: Pinned views stack up; Rest and Hidden start fresh. The peek
// view (Expanded) is only the way in: it is never stacked, so Back never returns to it.
function trail(s, cfg) {
    if (s.phase !== Phase.Pinned && s.phase !== Phase.Peek) return []
    return s.view === cfg.peekView ? s.history : s.history.concat([here(s)])
}

// A service view: one that goes back to the hub before the island collapses.
function service(view, cfg) {
    return cfg.hubView !== undefined && cfg.hubView >= 0 && cfg.known(cfg.hubView)
        && view !== cfg.restView && view !== cfg.peekView && view !== cfg.hubView
}
// The hub, Pinned, with nothing behind it and its own countdown.
function toHub(s, e, cfg) {
    return enter(set(s, { history: [] }), cfg, Phase.Pinned, cfg.hubView, cfg.timeout(cfg.hubView))
}

// Where a view is anchored. The resting view always centres; no coordinate = centre.
function anchor(view, e, cfg) { return view === cfg.restView || e.x === undefined ? -1 : e.x }

// ---- the one way to change phase ---------------------------------------------
// `peeking` is cleared on every phase change (reveal() sets it after entering Rest), so the peek
// key never outlives its Rest: a release that never arrives can't hold anything afterwards.
function enter(s, cfg, phase, view, ms, e) {
    e = e || {}
    return start(set(s, {
        phase: phase, view: view, ms: ms, x: anchor(view, e, cfg), peeking: false,
        prio: e.priority !== undefined ? e.priority : cfg.priority(view)
    }))
}

// ---- transitions: (state, event, cfg) -> state -------------------------------
function rest(s, e, cfg)     { return enter(set(s, { history: [] }), cfg, Phase.Rest, cfg.restView, restMs(s, cfg)) }
// Every road back to Rest first delivers the alert that was waiting, if any.
function toRest(s, e, cfg)   { return s.queued >= 0 ? deliver(s, e, cfg) : rest(s, e, cfg) }
function toHidden(s, e, cfg) { return enter(set(s, { history: [] }), cfg, Phase.Hidden, cfg.restView, 0) }
function toPeek(s, e, cfg)   { return cfg.peekView < 0 ? s : enter(s, cfg, Phase.Peek, cfg.peekView, 0) }
// A view the user/IPC may open or the system may alert: registered, and not the resting view.
// The resting view has no timeout and no countdown, so pinning it would never close.
function usable(view, cfg) { return cfg.known(view) && view !== cfg.restView }

function toPinned(s, e, cfg) {
    if (!cfg.known(e.view)) return s
    if (e.view === cfg.restView) return toRest(s, e, cfg)        // "open compact" means "go home"
    // pinning the view that is peeking (a click on the peek) keeps it, it doesn't stack it
    const history = s.phase === Phase.Peek && e.view === s.view ? s.history : trail(s, cfg)
    // opening is the user's choice, not an alert: the view's own priority
    return enter(set(s, { history: history }), cfg, Phase.Pinned, e.view, cfg.timeout(e.view), { x: e.x })
}
function toggle(s, e, cfg)   { return e.view === s.view ? toRest(s, e, cfg) : toPinned(s, e, cfg) }
function grace(s, e, cfg)    { return set(s, { timer: { ms: cfg.graceMs, kind: "grace" } }) }

// Back: pop the last entry and restore its view AND its anchor. Empty history: a service view goes
// to the hub, anything else closes.
function goBack(s, e, cfg) {
    if (s.history.length === 0) return service(s.view, cfg) ? toHub(s, e, cfg) : toRest(s, e, cfg)
    const p = s.history[s.history.length - 1]
    return enter(set(s, { history: s.history.slice(0, -1) }), cfg, Phase.Pinned, p.view, cfg.timeout(p.view), p)
}

// ---- triggered views (toasts) --------------------------------------------------
// What a toast leaves behind to return to: a Pinned view stacks up; toast-over-toast keeps what
// the first one stacked; anything else (Rest, Hidden, Peek) leaves nothing.
function toastTrail(s) {
    if (s.phase === Phase.Pinned) return s.history.concat([here(s)])
    return s.phase === Phase.Toast ? s.history : []
}

// The one way into Toast: show `view` at `priority`, centred (an alert has no click to anchor to),
// with the countdown from its Registry entry. Same view again = refresh: the countdown restarts.
function toast(s, view, priority, history, cfg) {
    return enter(set(s, { history: history }), cfg, Phase.Toast, view, cfg.timeout(view), { priority: priority })
}

function toToast(s, e, cfg) { return usable(e.view, cfg) ? toast(s, e.view, prio(e, cfg), toastTrail(s), cfg) : s }

// Remember a blocked alert, if its Registry entry says it is worth waiting for. One slot: the
// highest priority wins, the newest wins a tie. The same view again keeps the higher priority.
function park(s, view, priority, cfg) {
    if (!cfg.queues(view)) return s
    if (view === s.queued) return set(s, { queuedPrio: Math.max(priority, s.queuedPrio) })
    return s.queued < 0 || priority >= s.queuedPrio ? set(s, { queued: view, queuedPrio: priority }) : s
}

// Show what was waiting. It returns to Rest afterwards, not to anything that was open before.
function deliver(s, e, cfg) {
    const v = s.queued, p = s.queuedPrio
    const cleared = set(s, { queued: -1, queuedPrio: -1 })
    return cfg.known(v) ? toast(cleared, v, p, [], cfg) : rest(cleared, e, cfg)
}

// Alert while a Pinned view is open: only a higher priority may interrupt, and never while the
// user is holding the island. Otherwise it waits (or is dropped).
function alertPinned(s, e, cfg) {
    if (!usable(e.view, cfg) || e.view === s.view) return s
    const p = prio(e, cfg)
    return p > s.prio && !holding(s) ? toToast(s, e, cfg) : park(s, e.view, p, cfg)
}

// Alert while a toast is showing: same view refreshes (keeping the higher priority: what it shows
// now includes the urgent thing), equal or higher priority replaces it (the replaced toast waits if
// it is allowed to), lower priority waits (or is dropped).
function alertToast(s, e, cfg) {
    if (!usable(e.view, cfg)) return s
    const p = prio(e, cfg)
    if (e.view === s.view) return toast(s, s.view, Math.max(p, s.prio), s.history, cfg)
    if (p >= s.prio) return toToast(park(s, s.view, s.prio, cfg), e, cfg)
    return park(s, e.view, p, cfg)
}

// A toast is over (expired, dismissed or backed out of): return to what it interrupted, else show
// what was waiting, else settle. Auto-hide goes straight back to Hidden: no compact flash.
function toastEnd(s, e, cfg) {
    if (s.history.length > 0) return goBack(s, e, cfg)
    if (s.queued >= 0)        return deliver(s, e, cfg)
    return s.autoHide ? toHidden(s, e, cfg) : rest(s, e, cfg)
}

// Hover at Rest: wait cfg.hoverMs before peeking (0 = instant). With no peek view, hovering just
// holds the linger timer (rearm sees "holding" and drops it).
function intent(s, e, cfg) {
    if (cfg.peekView < 0) return rearm(s)
    return cfg.hoverMs > 0 ? set(s, { timer: { ms: cfg.hoverMs, kind: "intent" } }) : toPeek(s, e, cfg)
}

// A timer fired at Rest. It is either the hover-intent timer (only armed while hovered) or the
// linger timer (only armed while not hovered), so `hovered` says which one it was.
function lapse(s, e, cfg) {
    if (s.hovered)  return toPeek(s, e, cfg)
    if (s.autoHide && !holding(s)) return toHidden(s, e, cfg)
    return s
}

// A pinned view's countdown ended: back to the hub first (a service view), else home. A parked alert
// still comes first.
function lapsePinned(s, e, cfg) {
    if (s.queued >= 0) return deliver(s, e, cfg)
    return service(s.view, cfg) ? toHub(s, e, cfg) : toRest(s, e, cfg)
}

// Pointer left: the peek collapses after graceMs, unless it came back.
function letGo(s, e, cfg)  { return s.hovered ? s : grace(s, e, cfg) }

// The peek key shows the rest view for as long as it is held.
// Pressed at Hidden: reveal the island at Rest, held.
function reveal(s, e, cfg) { return keep(rest(s, e, cfg), e, cfg) }
// Pressed at Rest: hold it there (no linger). While hovered, the hover intent keeps running.
function keep(s, e, cfg)   { const k = set(s, { peeking: true }); return s.hovered ? k : rearm(k) }
// Released: auto-hide hides at once. The pointer still on the island (or at the edge) keeps it,
// and letting go of that starts the usual linger. A key pressed in another phase holds nothing here.
function release(s, e, cfg) {
    if (!s.peeking) return s
    const r = set(s, { peeking: false })
    if (r.hovered) return r                    // a running hover intent stays: rearm() would drop it
    return r.autoHide && !holding(r) ? toHidden(r, e, cfg) : rearm(r)
}

// Auto-hide switched on/off while Rest: retime the linger.
function retime(s, e, cfg)  { return rearm(set(s, { ms: restMs(s, cfg) })) }
// Auto-hide switched off while Hidden: come back.
function unhide(s, e, cfg)  { return s.autoHide ? s : toRest(s, e, cfg) }

// ---- facts tracked in every phase, before the phase sees the event ------------
function track(s, e) {
    switch (e.type) {
    case Event.Hover:   return set(s, { hovered: true, timer: s.phase === Phase.Peek ? null : s.timer })
    case Event.Leave:   return set(s, { hovered: false })
    case Event.Reach:   return set(s, { edge: true })
    case Event.Retreat: return set(s, { edge: false })
    case Event.Mode:    return set(s, { autoHide: !!e.on })
    case Event.Expire:  return set(s, { timer: null })     // it fired: never reuse the spent object
    }
    return s
}

// ---- transition table: data, not code -----------------------------------------
var table = {}
table[Phase.Hidden] = {
    [Event.Reach]:   toRest,               // pointer hit the top-edge hot zone
    [Event.Peek]:    reveal,               // the peek key shows the rest view while held
    [Event.Open]:    toPinned,             // IPC can open straight from hidden
    [Event.Alert]:   toToast,
    [Event.Mode]:    unhide
}
table[Phase.Rest] = {
    [Event.Hover]:   intent,
    [Event.Leave]:   rearm,                // starts the linger timer (auto-hide) or clears hover intent
    [Event.Reach]:   rearm,                // pointer in the hot zone holds the linger...
    [Event.Retreat]: rearm,                // ...and leaving it starts the linger
    [Event.Peek]:    keep,                 // the peek key holds the rest view...
    [Event.Unpeek]:  release,              // ...and releasing it hides it (auto-hide)
    [Event.Open]:    toPinned,
    [Event.Alert]:   toToast,
    [Event.Mode]:    retime,
    [Event.Expire]:  lapse
}
table[Phase.Peek] = {
    [Event.Leave]:   letGo,                // collapse after a short grace
    [Event.Open]:    toPinned,
    [Event.Alert]:   toToast,
    [Event.Close]:   toRest,
    [Event.Back]:    toRest,
    [Event.Expire]:  toRest
}
table[Phase.Pinned] = {
    [Event.Hover]:   rearm,                // wanted() sees "holding" and drops the timer
    [Event.Leave]:   rearm,                // ...and sees "not holding" and restarts it
    [Event.Reach]:   rearm,
    [Event.Retreat]: rearm,
    [Event.Alert]:   alertPinned,
    [Event.Open]:    toggle,               // opening the open view closes it
    [Event.Close]:   toRest,
    [Event.Back]:    goBack,
    [Event.Key]:     start,                // a keystroke: the countdown starts over (unless held)
    [Event.Expire]:  lapsePinned           // a service view goes to the hub, the hub goes home
}
table[Phase.Toast] = {
    [Event.Hover]:   rearm,                // a toast is held like a pinned view
    [Event.Leave]:   rearm,
    [Event.Reach]:   rearm,
    [Event.Retreat]: rearm,
    [Event.Alert]:   alertToast,
    [Event.Open]:    toPinned,             // click the toast: pin its view
    [Event.Close]:   toastEnd,
    [Event.Back]:    toastEnd,
    [Event.Expire]:  toastEnd
}

function reduce(s, e, cfg) {
    const t = track(s, e)
    const row = table[t.phase]
    const h = row ? row[e.type] : undefined
    return h ? h(t, e, cfg) : t
}