// Run: node modules/tests/machine.test.js
// Loads Machine.js (minus `.pragma library`) into a vm context and replays event sequences.
const fs = require("fs"), vm = require("vm"), path = require("path"), assert = require("assert")

const src = fs.readFileSync(path.join(__dirname, "../island/Machine.js"), "utf8")
                .replace(/^\.pragma library.*$/m, "")
const ctx = vm.createContext({}); vm.runInContext(src, ctx)
const M = ctx

// ---- fake Registry (mirrors Registry.qml) -----------------------------------------------------
const V = { Compact: 0, Expanded: 1, Network: 2, Launcher: 3, Bluetooth: 4, Volume: 5, Brightness: 6, Notifications: 7,
            Media: 8, Battery: 9, Clock: 10, Power: 11, Theme: 12, Workspaces: 13, Tabs: 14, Dashboard: 15, Switcher: 16 }
const REG = {
    [V.Compact]:    { priority: 0, timeout: 0 },
    [V.Expanded]:   { priority: 1, timeout: 4000 },
    [V.Network]:    { priority: 2, timeout: 5000 },
    [V.Launcher]:   { priority: 2, timeout: 8000 },
    [V.Bluetooth]:  { priority: 2, timeout: 5000 },
    [V.Volume]:     { priority: 1, timeout: 1500, queue: false },
    [V.Brightness]: { priority: 1, timeout: 1500, queue: false },
    [V.Notifications]: { priority: 2, critical: 3, timeout: 0, queue: true },
    [V.Media]:      { priority: 2, timeout: 8000 },
    [V.Battery]:    { priority: 2, critical: 3, timeout: 4000, queue: true },
    [V.Clock]:      { priority: 2, timeout: 8000 },
    [V.Power]:      { priority: 2, timeout: 8000 },
    [V.Theme]:      { priority: 2, timeout: 8000 },
    [V.Workspaces]: { priority: 2, timeout: 8000 },
    [V.Tabs]:       { priority: 2, timeout: 8000 },
    [V.Dashboard]:  { priority: 2, timeout: 12000 },
    [V.Switcher]:   { priority: 1, timeout: 1200, queue: false },
}
const cfg = {
    restView: V.Compact, peekView: V.Expanded, graceMs: 140, hoverMs: 140, hideMs: 700,
    known:    v => REG[v] !== undefined,
    priority: v => REG[v] ? REG[v].priority : -1,
    queues:   v => REG[v] ? !!REG[v].queue : false,
    timeout:  v => REG[v] ? REG[v].timeout : 0,
}
const run = (s, ...evs) => evs.reduce((st, e) => M.reduce(st, typeof e === "string" ? { type: e } : e, cfg), s)
const E = M.Event, P = M.Phase
const open  = (view, x) => ({ type: E.Open, view, x })
const alert = (view, priority) => ({ type: E.Alert, view, priority })
const CRIT = REG[V.Notifications].critical

let pass = 0, fail = 0
function test(name, fn) {
    try { fn(); pass++; console.log("  ok   " + name) }
    catch (err) { fail++; console.log("  FAIL " + name + "\n         " + err.message.split("\n")[0]) }
}

console.log("timers")
test("rearm keeps the same timer object when nothing that holds it changed", () => {
    let s = run(M.initial(V.Compact, false), open(V.Network))
    const t = s.timer
    assert.ok(t && t.ms === 5000)
    assert.strictEqual(run(s, E.Leave).timer, t, "Leave while not hovered")
    assert.strictEqual(run(s, E.Retreat).timer, t, "Retreat while not at the edge")
})
test("hover drops the timer, leaving restarts it with a fresh object", () => {
    let s = run(M.initial(V.Compact, false), open(V.Network))
    const t = s.timer
    const held = run(s, E.Hover); assert.strictEqual(held.timer, null)
    const back = run(held, E.Leave); assert.ok(back.timer && back.timer !== t)
    assert.strictEqual(run(back, E.Leave).timer, back.timer, "second Leave keeps it")
})
test("same toast again restarts the countdown (new object)", () => {
    let s = run(M.initial(V.Compact, false), alert(V.Volume))
    const t = s.timer
    assert.ok(t)
    assert.notStrictEqual(run(s, alert(V.Volume)).timer, t)
})
test("re-opening a different view restarts the countdown even with equal ms", () => {
    let s = run(M.initial(V.Compact, false), open(V.Network))
    assert.notStrictEqual(run(s, open(V.Bluetooth)).timer, s.timer)   // both 5000
})
test("expire clears the stale timer", () => {
    let s = run(M.initial(V.Compact, false), open(V.Network))
    assert.strictEqual(run(s, E.Expire).phase, P.Rest)
    const rest = run(M.initial(V.Compact, true), E.Reach, E.Retreat)           // Rest, linger armed
    assert.ok(rest.timer)
    assert.strictEqual(run(rest, E.Expire).phase, P.Hidden)
    assert.strictEqual(run(rest, E.Expire).timer, null)
})
test("a timer of another kind is never reused for the linger", () => {
    const c = Object.assign({}, cfg, { hideMs: 140 })                          // same ms as hoverMs
    let s = M.reduce(M.initial(V.Compact, true), { type: E.Reach }, c)
    s = M.reduce(s, { type: E.Retreat }, c)                                    // linger {140}
    s = M.reduce(s, { type: E.Hover }, c)                                      // intent {140}
    const intent = s.timer
    s = M.reduce(s, { type: E.Leave }, c)                                      // linger again
    assert.notStrictEqual(s.timer, intent)
})

console.log("rest view")
test("open <restView> goes home instead of pinning with no timeout", () => {
    const s = run(M.initial(V.Compact, false), open(V.Network), open(V.Compact))
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.view, V.Compact)
})
test("open <restView> from Hidden shows Rest, not a stuck Pinned", () => {
    const s = run(M.initial(V.Compact, true), open(V.Compact))
    assert.strictEqual(s.phase, P.Rest)
})
test("alert <restView> is ignored", () => {
    const s0 = M.initial(V.Compact, false)
    assert.strictEqual(run(s0, alert(V.Compact)).phase, P.Rest)
    const pinned = run(s0, open(V.Network))
    assert.strictEqual(run(pinned, alert(V.Compact)).phase, P.Pinned)
})

test("pinning the peeking view (a click on the peek) leaves no history entry", () => {
    let s = run(M.initial(V.Compact, false), E.Hover, E.Expire)                  // peeking Expanded
    s = run(s, open(V.Expanded))
    assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.history.length, 0)
    assert.strictEqual(run(s, E.Back).phase, P.Rest)                             // Back closes, no Expanded twice
    s = run(M.initial(V.Compact, false), E.Hover, E.Expire, open(V.Network))     // another view from the peek
    assert.strictEqual(s.history.length, 1)
})

console.log("anchor")
test("Back restores the view's anchor x; the rest view always centres", () => {
    let s = run(M.initial(V.Compact, false), open(V.Expanded, 120), open(V.Network, 300))
    assert.strictEqual(s.x, 300)
    s = run(s, E.Back); assert.strictEqual(s.view, V.Expanded); assert.strictEqual(s.x, 120)
    assert.strictEqual(run(s, E.Close).x, -1)
})

console.log("keyboard")
test("a keystroke restarts the pinned countdown", () => {
    const s = run(M.initial(V.Compact, false), open(V.Expanded))
    const k = run(s, E.Key)
    assert.strictEqual(k.phase, P.Pinned)
    assert.strictEqual(k.timer.ms, REG[V.Expanded].timeout)
    assert.notStrictEqual(k.timer, s.timer)                // a new object: the shell restarts its Timer
})
test("a keystroke while hovered keeps the countdown held", () => {
    const s = run(M.initial(V.Compact, false), open(V.Expanded), E.Hover, E.Key)
    assert.strictEqual(s.timer, null)
})
test("a keystroke in Peek changes nothing", () => {
    const s = run(M.initial(V.Compact, false), E.Hover, E.Expire)
    assert.strictEqual(run(s, E.Key).phase, P.Peek)
    assert.strictEqual(run(s, E.Key).timer, s.timer)
})

console.log("peek key (shows the rest view while held)")
test("peek reveals the rest view from Hidden, held: no linger", () => {
    const s = run(M.initial(V.Compact, true), E.Peek)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.view, V.Compact)
    assert.strictEqual(s.peeking, true); assert.strictEqual(s.timer, null)
})
test("releasing the key hides at once (auto-hide)", () => {
    const s = run(M.initial(V.Compact, true), E.Peek, E.Unpeek)
    assert.strictEqual(s.phase, P.Hidden); assert.strictEqual(s.peeking, false)
})
test("the key holds a lingering Rest; releasing it hides", () => {
    let s = run(M.initial(V.Compact, true), E.Reach, E.Retreat)                 // Rest, linger armed
    s = run(s, E.Peek); assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.timer, null)
    assert.strictEqual(run(s, E.Unpeek).phase, P.Hidden)
})
test("the key never shows the peek view", () => {
    for (const s of [run(M.initial(V.Compact, true), E.Peek), run(M.initial(V.Compact, false), E.Peek)])
        assert.strictEqual(s.view, V.Compact)
})
test("the pointer leaving doesn't hide a held Rest", () => {
    const s = run(M.initial(V.Compact, true), E.Peek, E.Hover, E.Leave)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.timer, null)
})
test("releasing while hovered keeps the island; leaving then starts the linger", () => {
    let s = run(M.initial(V.Compact, true), E.Peek, E.Hover, E.Unpeek)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.timer.kind, "intent")   // hover intent still runs
    s = run(M.initial(V.Compact, true), E.Peek, E.Hover, E.Unpeek, E.Leave)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.timer.kind, "hold"); assert.strictEqual(s.timer.ms, 700)
})
test("pressing the key while hovered keeps the hover intent", () => {
    const s = run(M.initial(V.Compact, true), E.Reach, E.Retreat, E.Hover)
    const t = s.timer
    assert.strictEqual(run(s, E.Peek).timer, t)
})
test("without auto-hide, the key changes nothing visible", () => {
    const s = run(M.initial(V.Compact, false), E.Peek, E.Unpeek)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.timer, null)
})
test("the peek key never outlives its Rest", () => {
    const held = run(M.initial(V.Compact, true), E.Peek)
    for (const s of [run(held, open(V.Network)), run(held, alert(V.Volume)), run(held, E.Hover, E.Expire)]) {
        assert.strictEqual(s.peeking, false, s.phase)
    }
})
test("a release whose press was ignored doesn't cut the linger short", () => {
    let s = run(M.initial(V.Compact, true), open(V.Network), E.Peek, E.Expire)  // pressed while Pinned
    assert.strictEqual(s.phase, P.Rest); assert.ok(s.timer)
    assert.strictEqual(run(s, E.Unpeek).phase, P.Rest)
})
test("the peek key is ignored while a view is pinned, a toast is up, or a hover peek shows", () => {
    const pinned = run(M.initial(V.Compact, false), open(V.Network))
    const s = run(pinned, E.Peek)
    assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.timer, pinned.timer); assert.strictEqual(s.peeking, false)
    assert.strictEqual(run(M.initial(V.Compact, false), alert(V.Volume), E.Peek).phase, P.Toast)
    const grace = run(M.initial(V.Compact, false), E.Hover, E.Expire, E.Leave)       // hover peek, grace running
    assert.strictEqual(run(grace, E.Peek).timer, grace.timer)
})
test("peekView -1 doesn't turn the key off", () => {
    const off = Object.assign({}, cfg, { peekView: -1 })
    const s = M.reduce(M.initial(V.Compact, true), { type: E.Peek }, off)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.peeking, true)
})

console.log("existing behaviour (regression)")
test("hover intent then peek", () => {
    let s = run(M.initial(V.Compact, false), E.Hover)
    assert.deepStrictEqual(s.timer && s.timer.ms, 140)
    s = run(s, E.Expire); assert.strictEqual(s.phase, P.Peek); assert.strictEqual(s.view, V.Expanded)
})
test("peek grace then Rest", () => {
    let s = run(M.initial(V.Compact, false), E.Hover, E.Expire, E.Leave)
    assert.strictEqual(s.timer.ms, 140)
    assert.strictEqual(run(s, E.Expire).phase, P.Rest)
})
test("auto-hide: reveal, linger, hide", () => {
    let s = run(M.initial(V.Compact, true), E.Reach)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.timer, null)
    s = run(s, E.Retreat); assert.strictEqual(s.timer.ms, 700)
    assert.strictEqual(run(s, E.Expire).phase, P.Hidden)
})
test("toast over pinned: higher priority interrupts and Back returns", () => {
    let s = run(M.initial(V.Compact, false), open(V.Expanded), alert(V.Notifications))
    assert.strictEqual(s.phase, P.Toast)
    s = run(s, E.Expire); assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.view, V.Expanded)
})
test("toast over pinned: equal/lower priority waits or is dropped", () => {
    let s = run(M.initial(V.Compact, false), open(V.Network), alert(V.Notifications))
    assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.queued, V.Notifications)   // parked
    s = run(M.initial(V.Compact, false), open(V.Network), alert(V.Volume))
    assert.strictEqual(s.queued, -1)                                                // volume dropped
})
test("no interruption while hovered", () => {
    const s = run(M.initial(V.Compact, false), open(V.Expanded), E.Hover, alert(V.Notifications))
    assert.strictEqual(s.phase, P.Pinned)
})
test("queued alert is delivered when going home", () => {
    let s = run(M.initial(V.Compact, false), open(V.Network), alert(V.Notifications), E.Close)
    assert.strictEqual(s.phase, P.Toast); assert.strictEqual(s.view, V.Notifications)
})
test("toast replacement parks queueable toast", () => {
    let s = run(M.initial(V.Compact, false), alert(V.Volume), alert(V.Notifications))
    assert.strictEqual(s.view, V.Notifications); assert.strictEqual(s.queued, -1)   // volume: queue false
    s = run(M.initial(V.Compact, false), alert(V.Notifications), alert(V.Network, 2))
    assert.strictEqual(s.view, V.Network); assert.strictEqual(s.queued, V.Notifications)
    s = run(s, E.Expire); assert.strictEqual(s.view, V.Notifications)
})

console.log("alert priority (travels with the event)")
test("no priority on the event = the view's", () => {
    const s = run(M.initial(V.Compact, false), alert(V.Notifications))
    assert.strictEqual(s.prio, 2)
})
test("a critical alert interrupts an equal-priority pinned view; a normal one waits", () => {
    const pinned = run(M.initial(V.Compact, false), open(V.Network))                // priority 2
    assert.strictEqual(run(pinned, alert(V.Notifications)).phase, P.Pinned)
    const s = run(pinned, alert(V.Notifications, CRIT))
    assert.strictEqual(s.phase, P.Toast); assert.strictEqual(s.prio, CRIT)
    const back = run(s, E.Close)
    assert.strictEqual(back.view, V.Network); assert.strictEqual(back.prio, 2)      // Back restores its priority
})
test("refreshing the same toast keeps the higher priority", () => {
    let s = run(M.initial(V.Compact, false), alert(V.Notifications, CRIT), alert(V.Notifications))
    assert.strictEqual(s.prio, CRIT)
    s = run(s, alert(V.Network, 2))                                                 // lower: parked, and network does not queue
    assert.strictEqual(s.view, V.Notifications)
})
test("a critical toast is not replaced by an equal-priority view", () => {
    const s = run(M.initial(V.Compact, false), alert(V.Notifications, CRIT), alert(V.Launcher))
    assert.strictEqual(s.view, V.Notifications)
})
test("a parked alert keeps its priority until delivered", () => {
    let s = run(M.initial(V.Compact, false), open(V.Expanded), E.Hover, alert(V.Notifications, CRIT))
    assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.queuedPrio, CRIT)  // hovered: waits
    s = run(s, alert(V.Notifications)); assert.strictEqual(s.queuedPrio, CRIT)       // same view: stays urgent
    s = run(s, E.Close)
    assert.strictEqual(s.phase, P.Toast); assert.strictEqual(s.prio, CRIT); assert.strictEqual(s.queued, -1)
})
test("pinning the toast's view (popups -> center) uses the view's own priority", () => {
    const s = run(M.initial(V.Compact, false), alert(V.Notifications, CRIT), open(V.Notifications))
    assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.prio, 2)
})
test("toggle: opening the open view closes it", () => {
    const s = run(M.initial(V.Compact, false), open(V.Network), open(V.Network))
    assert.strictEqual(s.phase, P.Rest)
})
test("unknown views are ignored", () => {
    const s0 = M.initial(V.Compact, false)
    assert.strictEqual(run(s0, open(99)).phase, P.Rest)
    assert.strictEqual(run(s0, alert(99)).phase, P.Rest)
    assert.strictEqual(run(s0, alert(undefined)).phase, P.Rest)
})
test("auto-hide: toast end goes straight to Hidden", () => {
    const s = run(M.initial(V.Compact, true), alert(V.Volume), E.Expire)
    assert.strictEqual(s.phase, P.Hidden)
})

console.log("the hub (Tabs) and the workspace switcher")
test("Back goes to whatever was open before: the glance, Tabs, a view", () => {
    let s = run(M.initial(V.Compact, false), E.Hover, E.Expire)            // hover intent -> peek
    s = run(s, open(V.Tabs), open(V.Network))
    s = run(s, E.Back); assert.strictEqual(s.view, V.Tabs); assert.strictEqual(s.phase, P.Pinned)
    s = run(s, E.Back); assert.strictEqual(s.view, V.Expanded); assert.strictEqual(s.phase, P.Pinned)
    s = run(s, E.Back); assert.strictEqual(s.phase, P.Rest)
})
test("Close (Escape) goes home from anywhere, history and all", () => {
    const s = run(M.initial(V.Compact, false), open(V.Tabs), open(V.Network), open(V.Bluetooth), E.Close)
    assert.strictEqual(s.phase, P.Rest); assert.strictEqual(s.history.length, 0)
})
test("a pinned view's countdown goes home, not back", () => {
    assert.strictEqual(run(M.initial(V.Compact, false), open(V.Tabs), open(V.Media), E.Expire).phase, P.Rest)
})
test("a workspace switch never interrupts an open view, and isn't kept for later", () => {
    let s = run(M.initial(V.Compact, false), open(V.Tabs), alert(V.Switcher))
    assert.strictEqual(s.view, V.Tabs)
    assert.strictEqual(s.queued, -1)
})
test("a workspace switch at rest is a short toast; auto-hide hides after it", () => {
    let s = run(M.initial(V.Compact, true), alert(V.Switcher))
    assert.strictEqual(s.phase, P.Toast); assert.strictEqual(s.timer.ms, 1200)
    s = run(s, E.Expire)
    assert.strictEqual(s.phase, P.Hidden)
})
test("switching again while the switcher shows refreshes its countdown", () => {
    let s = run(M.initial(V.Compact, false), alert(V.Switcher))
    const t = s.timer
    s = run(s, alert(V.Switcher))
    assert.strictEqual(s.view, V.Switcher); assert.ok(s.timer && s.timer !== t)
})
test("a notification replaces the switcher; the switcher isn't parked", () => {
    let s = run(M.initial(V.Compact, false), alert(V.Switcher), alert(V.Notifications))
    assert.strictEqual(s.view, V.Notifications); assert.strictEqual(s.queued, -1)
})

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail ? 1 : 0)