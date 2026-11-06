.pragma library

// Pure: no QML, no timers, no clock, no globals, so every transition can be replayed in a test.
// States are never mutated, and the timer is part of the state: the shell arms its one real Timer
// whenever state.timer changes identity. docs/state-machine.md has the phases and the events.
//
//   prio   what is showing: the alert's own, else the view's. Kept in history and in the queue,
//          so an urgent alert stays urgent wherever it goes
//   timer  { ms, kind } | null; kind: "hold" (phase countdown) | "intent" (hover) | "grace" (peek)
//   x      the x to centre on, -1 = the screen centre

var Phase = { Hidden: "hidden", Rest: "rest", Peek: "peek", Pinned: "pinned", Toast: "toast" }
var Event = { Hover: "hover", Leave: "leave", Reach: "reach", Retreat: "retreat", Mode: "mode",
              Peek: "peek", Unpeek: "unpeek",
              Open: "open", Close: "close", Back: "back", Alert: "alert", Key: "key", Expire: "expire" }

function initial(restView, autoHide) {
    return { phase: autoHide ? Phase.Hidden : Phase.Rest, view: restView, prio: 0,
             hovered: false, edge: false, peeking: false, x: -1, ms: 0, timer: null,
             history: [], autoHide: !!autoHide, queued: -1, queuedPrio: -1 }
}

function set(s, patch) { return Object.assign({}, s, patch) }
function timed(s)      { return s.phase === Phase.Pinned || s.phase === Phase.Rest || s.phase === Phase.Toast }
// The pointer is on the island or in the top-edge hot zone, or the peek key is held: countdowns pause.
function holding(s)    { return s.hovered || s.edge || s.peeking }
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
    // While hovered wanted() is null, and that would drop the running hover intent: the peek would never come.
    if (t && t.kind === "intent" && s.hovered) return s
    return w && t && t.kind === w.kind && t.ms === w.ms ? s : set(s, { timer: w })
}

function restMs(s, cfg) { return s.autoHide ? cfg.hideMs : 0 }

// The history a new view leaves behind. A toast passes on what it interrupted, whether it is pinned or
// replaced by another toast. Peek only lives under the pointer, so Back never returns to it.
function trail(s) {
    if (s.phase === Phase.Pinned) return s.history.concat([here(s)])
    return s.phase === Phase.Toast ? s.history : []
}

function anchor(view, e, cfg) { return view === cfg.restView || e.x === undefined ? -1 : e.x }

// The one way to change phase. `peeking` is cleared on every change (reveal() sets it after entering
// Rest), so the peek key never outlives its Rest: a release that never arrives can't hold anything afterwards.
function enter(s, cfg, phase, view, ms, e) {
    e = e || {}
    const shown = s.queued === view     // however it reached the screen, it mustn't show again from the queue
    return start(set(s, {
        phase: phase, view: view, ms: ms, x: anchor(view, e, cfg), peeking: false,
        queued: shown ? -1 : s.queued, queuedPrio: shown ? -1 : s.queuedPrio,
        prio: e.priority !== undefined ? e.priority : cfg.priority(view)
    }))
}

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
    // opening is the user's choice, not an alert: the view's own priority
    return enter(set(s, { history: trail(s) }), cfg, Phase.Pinned, e.view, cfg.timeout(e.view), { x: e.x })
}
function toggle(s, e, cfg)   { return e.view === s.view ? toRest(s, e, cfg) : toPinned(s, e, cfg) }
function grace(s, e, cfg)    { return set(s, { timer: { ms: cfg.graceMs, kind: "grace" } }) }

function goBack(s, e, cfg) {
    if (s.history.length === 0) return toRest(s, e, cfg)
    const p = s.history[s.history.length - 1]
    return enter(set(s, { history: s.history.slice(0, -1) }), cfg, Phase.Pinned, p.view, cfg.timeout(p.view), p)
}

// An alert has no click to anchor to, so a toast is centred. Same view again = refresh: the countdown restarts.
function toast(s, view, priority, history, cfg) {
    return enter(set(s, { history: history }), cfg, Phase.Toast, view, cfg.timeout(view), { priority: priority })
}

function toToast(s, e, cfg) { return usable(e.view, cfg) ? toast(s, e.view, prio(e, cfg), trail(s), cfg) : s }

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

// Auto-hide goes straight back to Hidden: no compact flash.
function toastEnd(s, e, cfg) {
    if (s.history.length > 0) return goBack(s, e, cfg)
    if (s.queued >= 0)        return deliver(s, e, cfg)
    return s.autoHide ? toHidden(s, e, cfg) : rest(s, e, cfg)
}

// With no peek view, hovering just holds the linger timer (rearm sees "holding" and drops it).
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

function letGo(s, e, cfg)  { return s.hovered ? s : grace(s, e, cfg) }

function reveal(s, e, cfg) { return keep(rest(s, e, cfg), e, cfg) }
function keep(s, e, cfg)   { return rearm(set(s, { peeking: true })) }
// Released: auto-hide hides at once. The pointer still on the island (or at the edge) keeps it,
// and letting go of that starts the usual linger. A key pressed in another phase holds nothing here.
function release(s, e, cfg) {
    if (!s.peeking) return s
    const r = set(s, { peeking: false })
    return r.autoHide && !holding(r) ? toHidden(r, e, cfg) : rearm(r)
}

function retime(s, e, cfg)  { return rearm(set(s, { ms: restMs(s, cfg) })) }
function unhide(s, e, cfg)  { return s.autoHide ? s : toRest(s, e, cfg) }

// Tracked in every phase, before the phase sees the event, so no table row can forget one.
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

var table = {}
table[Phase.Hidden] = {
    [Event.Reach]:   toRest,
    [Event.Peek]:    reveal,
    [Event.Open]:    toPinned,
    [Event.Alert]:   toToast,
    [Event.Mode]:    unhide
}
table[Phase.Rest] = {
    [Event.Hover]:   intent,
    [Event.Leave]:   rearm,                // starts the linger timer (auto-hide) or clears hover intent
    [Event.Reach]:   rearm,
    [Event.Retreat]: rearm,
    [Event.Peek]:    keep,
    [Event.Unpeek]:  release,
    [Event.Open]:    toPinned,
    [Event.Alert]:   toToast,
    [Event.Mode]:    retime,
    [Event.Expire]:  lapse
}
table[Phase.Peek] = {
    [Event.Leave]:   letGo,
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
    [Event.Key]:     start,
    [Event.Expire]:  toRest
}
table[Phase.Toast] = {
    [Event.Hover]:   rearm,
    [Event.Leave]:   rearm,
    [Event.Reach]:   rearm,
    [Event.Retreat]: rearm,
    [Event.Alert]:   alertToast,
    [Event.Open]:    toPinned,
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