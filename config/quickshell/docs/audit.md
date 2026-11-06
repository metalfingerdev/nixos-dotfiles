# Audit: redundancy and the state machine (2026-10-30)

What was read: every doc, all of `modules/island/`, the tests, and a sweep of `views/`, `parts/`,
`overview/`, `services/` and `components/` for code written more than once or never reached.

How it was checked: every state-machine claim below was replayed against the real `Machine.js` with
the harness from `machine.test.js`. The keyboard claim was replayed with real key events in
`qmltestrunner`. The fixes proposed for `Machine.js` and `ViewLoader.qml` were applied to scratch
copies and the existing suites run against them. No code in the repo was changed.

Baseline: `machine.test.js` 50/50, `tst_keyboard.qml` 13/13.

## Status (2026-10-31)

Worked through, and each claim re-checked against the code first, because the code had moved since this
was written. Tests: `machine.test.js` 56/56, `tst_keyboard.qml` 15/15.

| Item | Outcome |
|---|---|
| B1, B2, B3 | fixed as proposed, with tests |
| B4 | fixed as proposed. `edged()` had already covered the edge events; the mode event still lost the intent |
| I1, I2 | not done: behaviour choices, still open |
| I3 | the doc sentence fixed (D2); `close` keeps its meaning on a toast |
| I4 | done (`Engine.toast`, `peeked`, `atRest`, `idle`); `Engine.peeking` removed in favour of the snapshot |
| I5 | no longer applies: the peek is `Expanded` now, a click on it opening Tabs is the design, and Peek leaves no history |
| I6, I7 | done |
| R1 | done, as `Audio.levelIcon`, `Backlight.icon` and the sliders themselves in `parts/` (`Audio.glyph` was taken) |
| R2, R3, R5, R7, R8, R9, R10, R12, R13 | done |
| R4 | no longer applies: `Expanded` uses MediaCard's `compact` |
| R6 | half: `showText` removed; `Expanded` uses `maxWidth` |
| R11 | done as `Energy.tone`, a Config role by name: Config can't see Energy, and services stay free of the theme |
| R14 | left alone, as suggested |
| D1, D2, D3 | done |

Everything below is the audit as written, with its line numbers from that day.

## At a glance

| # | What | Kind | Severity | Effort |
|---|---|---|---|---|
| [B1](#b1-keys-a-control-handles-never-restart-the-countdown) | Keys a control handles never restart the countdown | bug (keyboard → Engine) | medium | medium, removes ~35 lines |
| [B2](#b2-a-queued-alert-can-show-twice) | A queued alert can show twice | machine bug | medium | 2 lines |
| [B3](#b3-pinning-a-toast-forgets-what-it-interrupted) | Pinning a toast forgets what it interrupted | machine bug | low | 1 line |
| [B4](#b4-the-hover-intent-is-cancelled-by-edge-or-mode-events) | The hover intent is cancelled by edge or mode events | machine bug | low | 1 line, removes 2 special cases |
| [I1–I7](#improvements-to-the-machine-and-around-it) | Behaviour worth revisiting, robustness, tests | improvement | | |
| [R1–R14](#redundant-code) | Duplicated or unreachable code | simplification | | |
| [D1–D3](#docs-drift) | Docs that no longer match the code | docs | | |

## Bugs

### B1. Keys a control handles never restart the countdown

`key` is meant to be "any keystroke in the island" (state-machine.md), but only keys that reach
`ViewLoader` emit `activity()`. Qt's `Keys` accepts a key by default as soon as an item has a handler
for it (`Keys.onReturnPressed`, `Keys.onLeftPressed`, ...), so the key never bubbles up. Views that
take keys themselves call `Engine.key()` (Dashboard, Tabs, Power, Launcher, ...), but the
components don't.

Replayed with ViewLoader + a Pill + a Slider:

| Key | Did its job | `activity()` |
|---|---|---|
| Return on a Pill | yes | 0 |
| Space on a Pill | yes | 0 |
| Right ×2 on a Slider | yes (0 → 0.10) | 0 |
| Tab (for comparison) | yes | 1 |

Effect: a pinned view times out while you are using it from the keyboard. Only focus moves count.
Examples: Space-toggling Dashboard tiles (12 s), Left/Right on the Mixer's sliders (8 s), picking a
Segmented option in Settings or Theme (8 s) or Battery (4 s), Delete on a notification card in the dashboard.

Handlers that swallow the key: Pill, QuickTile, Tile, ListEntry, Chip, Segmented, Toggle, Slider,
Progress, WorkspaceButtons, StatusGroup, NotificationCard, Tabs' clock, Theme's Swatch.

**Fix, which is also the biggest simplification here:** let ViewLoader own Enter/Return/Space, and
Left/Right on a control that steps. Controls then only expose `press()`, `activate()` and `nudge(dir)`,
which most already have (`shortcut()` already calls `activate()` / `press()`).

```qml
// ViewLoader.qml, in the switch
case Qt.Key_Right:   if (!nudge(1)) move(1, 0);   break
case Qt.Key_Left:    if (!nudge(-1)) move(-1, 0); break
case Qt.Key_Return:
case Qt.Key_Enter:   event.accepted = press(false); break
case Qt.Key_Space:   event.accepted = press(true);  break

// Enter/Return: the focused control's press() (else activate()). Space: its activate().
function press(space) {
    const it = Window.activeFocusItem
    if (!inView(it)) return false
    if (!space && typeof it.press === "function") { it.press(); return true }
    if (typeof it.activate === "function") { it.activate(); return true }
    return false
}
// Left/Right on a control that steps (Slider, Progress): nudge(-1 | 1)
function nudge(dir) {
    const it = Window.activeFocusItem
    if (!inView(it) || typeof it.nudge !== "function") return false
    it.nudge(dir)
    return true
}
```

Then delete the Enter/Return/Space triples, and:

- Slider: `function nudge(dir) { const v = clamp(value + dir * step); moved(v); committed(v) }` and
  `function activate() { if (iconClickable) iconClicked() }`, in place of its four `Keys` lines.
- Progress: `function nudge(dir) { seek(clamp(fraction + dir * step)) }`, in place of its two.
- Toggle, StatusGroup's segment, Tabs' clock: rename the action to `activate()`.
- NotificationCard: rename the Enter action to `press()` (Space keeps doing nothing).
- Keep the handlers in text fields (SearchBar, Network's password, Theme's hex field and wallpaper
  grid). They accept keys on purpose and already call `Engine.key()`.

These rules match today's behaviour: QuickTile's Enter opens (`press`) and its Space switches
(`activate`), and every other control maps both keys to the same action. The one change is that
numpad Enter on a Slider now clicks its icon too (today only Return does).

Prototype (Pill and Slider changed as above): `tst_keyboard.qml` 13/13. Return, Space and Right each
emit `activity()` once, with no double action: the slider steps and keeps focus.

### B2. A queued alert can show twice

```
open Dashboard · alert Battery (2: parked) · alert Battery critical (3: interrupts)
  → toast Battery, history [Dashboard], queued Battery      ← still queued
expire → back to Dashboard · close → Battery toast AGAIN, from the queue
```

The same hole on the user's side: a notification is parked, and then you open the notification
center yourself. Closing the center delivers the parked popup view, which is empty by then, and
`Triggers.settle()` closes it a tick later, so an empty view flashes. The comment there
("delivered-but-already-empty") is working around this.

Cause: nothing takes a view out of the queue when it reaches the screen another way.
Fix: in `enter()`, the one way to change phase (diff below).

### B3. Pinning a toast forgets what it interrupted

```
open Dashboard · alert Notifications critical → toast, history [Dashboard]
click the toast (open Notifications) → pinned, history []      ← Dashboard dropped
back → Rest   (had the toast simply expired, Dashboard would have come back)
```

Cause: `trail()` (`Machine.js:66`) treats Toast like Rest, but `toastTrail()` already treats a
toast's history as what to return to. It's the same for toasts with `opens` (the volume toast opening
the dashboard). Fix: a toast passes its history on (diff below).

### B4. The hover intent is cancelled by edge or mode events

```
Rest · hover → intent timer (140 ms)
  + reach | retreat | mode   while still hovered → timer null: the peek never comes
```

Cause: `rearm()` knows only the hold timer. While hovered, `wanted()` is `null`, so it drops the
intent. `keep()` and `release()` already work around this (`s.hovered ? k : rearm(k)` and
`if (r.hovered) return r`), but the table's `reach`, `retreat` and `retime` don't.

When it happens: rarely. Examples are a key bound to `toggleAutohide` pressed while hovering, or, in
notch style, the pointer sliding along the top edge between the hot zone and the island if Qt
delivers the overlay's hover before the spacer's leave.

Fix: `rearm()` keeps a running intent while the pointer is still on the island. Then `keep()` and
`release()` no longer need their special cases.

### Fix for B2–B4

```diff
@@ function rearm(s) {
     const w = wanted(s), t = s.timer
+    if (t && t.kind === "intent" && s.hovered) return s
     return w && t && t.kind === w.kind && t.ms === w.ms ? s : set(s, { timer: w })
@@ function trail(s) {
-    return s.phase === Phase.Pinned || s.phase === Phase.Peek
-         ? s.history.concat([here(s)]) : []
+    if (s.phase === Phase.Pinned || s.phase === Phase.Peek) return s.history.concat([here(s)])
+    return s.phase === Phase.Toast ? s.history : []
@@ function enter(s, cfg, phase, view, ms, e) {
     e = e || {}
+    const shown = s.queued === view          // it was waiting: now it's on screen, so it waits no more
     return start(set(s, {
         phase: phase, view: view, ms: ms, x: anchor(view, e, cfg), peeking: false,
+        queued: shown ? -1 : s.queued, queuedPrio: shown ? -1 : s.queuedPrio,
@@
-function keep(s, e, cfg)   { const k = set(s, { peeking: true }); return s.hovered ? k : rearm(k) }
+function keep(s, e, cfg)   { return rearm(set(s, { peeking: true })) }
@@ function release(s, e, cfg) {
     const r = set(s, { peeking: false })
-    if (r.hovered) return r                    // a running hover intent stays: rearm() would drop it
     return r.autoHide && !holding(r) ? toHidden(r, e, cfg) : rearm(r)
```

With this applied, the existing 50 tests still pass. These four new ones fail on today's
`Machine.js` and pass with the fix (54/54):

```js
test("an alert shown while it also waits in the queue isn't shown again later", () => {
    let s = run(M.initial(V.Compact, false), open(V.Dashboard), alert(V.Battery), alert(V.Battery, 3))
    assert.strictEqual(s.view, V.Battery); assert.strictEqual(s.queued, -1)
    s = run(s, E.Expire, E.Close)
    assert.strictEqual(s.phase, P.Rest)
})
test("opening a view that waits in the queue takes it out of the queue", () => {
    const s = run(M.initial(V.Compact, false), open(V.Dashboard), alert(V.Notifications), open(V.Notifications))
    assert.strictEqual(s.queued, -1)
    assert.strictEqual(run(s, E.Close).phase, P.Rest)
})
test("pinning a toast keeps what it interrupted: Back returns there", () => {
    const s = run(M.initial(V.Compact, false), open(V.Dashboard), alert(V.Notifications, CRIT), open(V.Notifications), E.Back)
    assert.strictEqual(s.phase, P.Pinned); assert.strictEqual(s.view, V.Dashboard)
})
test("the hover intent survives the edge or the mode changing while hovered", () => {
    const s = run(M.initial(V.Compact, false), E.Hover)
    for (const e of [E.Reach, E.Retreat, { type: E.Mode, on: true }])
        assert.strictEqual(run(s, e).timer, s.timer, JSON.stringify(e))
})
```

The docs need two lines to match: state-machine.md's History section (a pinned toast keeps its
history) and Parking (a view that reaches the screen leaves the queue).

## Improvements to the machine and around it

These are working as written, but the behaviour or the structure is worth revisiting.

**I1. Alerts at Peek ignore priority.** Hovering the hub, any alert replaces it under the pointer,
and the hub doesn't come back:

```
peek Tabs · alert Volume (prio 1) → toast Volume, history [] · leave, expire → Rest
```

`Triggers.qml:49` special-cases the switcher toast for exactly this, but volume, brightness, battery
and notifications aren't covered. Suggestion: route Peek's `alert` through `alertPinned`. At Peek
the pointer is always on the island, so `holding()` is true and the alert is parked: `queue: true`
alerts show the moment the peek collapses (`toRest` delivers), and the rest are dropped.
`Triggers.qml:49-50` then go away. Trade-off: a notification waits until you leave the hub, which
shows the unread count on its bell anyway. A middle way is to let only a higher priority (critical)
interrupt.

**I2. An alert blocked only by hover waits for the whole view.** Dashboard pinned and hovered, then
a critical battery warning: it is parked (correct, you're holding the island). But when the pointer
leaves, the Dashboard counts down another 12 s before the warning shows. Suggestion: in Pinned,
`leave`/`retreat` delivers the parked alert as an interruption (a toast with history, like
`alertPinned`) when `queuedPrio > prio` and nothing holds.

**I3. `close` on a toast doesn't go home.** Toast + `close` runs `toastEnd`, which returns to the
interrupted pinned view. `state-machine.md:99` says close "goes straight to Rest from anywhere".
`Triggers.settle()` depends on close meaning "end this toast", so the doc sentence is what's wrong.
Alternatively split the event into `close` (home) and `dismiss` (end the toast). Today this shows up
with `qs ipc call island close` while a toast interrupts a view.

**I4. Phase strings outside the machine.** `Bar.qml:105-106` and `Triggers.qml:37, 49, 68` compare
`Engine.phase` with `"toast"`, `"rest"` and `"peek"`, and `Triggers.qml:37` repeats the "idle" test in
`Engine.qml:89`. Expose readonly booleans on Engine (`idle`, `toast`, `peek`) next to `hidden` and
`pinned`, so a phase rename can't silently break them. Also, `Engine.peeking` (the peek key) next
to the `peek` phase (hover) reads as the same thing. `peekKey` would say what it is.

**I5. A click on the peek always pins Tabs.** `Bar.qml:106` hard-codes `Engine.View.Tabs`. With
`peekView` set to another view, a click on the peek pins Tabs and stacks the peek view behind it.
Use `Engine.peekView >= 0 ? Engine.peekView : Engine.View.Tabs`.

**I6. Every Bar writes `Engine.hasKeyboard`** (`Bar.qml:160-163`). Only the active one should
(`if (root.active)`), so a screen change can never leave a stale `false` after a `true`. The risk is
low today, because the island only moves while idle (except IPC `screen`).

**I7. The test's Registry is copied by hand.** README asks to keep `REG` in sync with
`Registry.qml`. The harness could read the entries out of `Registry.qml` and the enum out of
`Engine.qml` (both are plain one-line literals), so it can't drift. Add the four tests above.

## Redundant code

These are safe simplifications: none of them changes the state machine or what a view does.

| # | What | Where | Suggestion |
|---|---|---|---|
| R1 | Volume icon ladder ×3, brightness ladder ×3 | `Volume.qml:12`, `Dashboard.qml:221`, `Mixer.qml:24-26` · `Brightness.qml:12`, `Dashboard.qml:233`, `Battery.qml:157` | `Audio.glyph` / `Backlight.glyph`, like `Net.icon` and `Energy.glyph` already are. Mixer's per-stream one: `Audio.glyphFor(level, muted)` |
| R2 | Power profile options ×2 | `Dashboard.qml:239-250`, `Battery.qml:162-173` | `Toggles.profiles` (key, label, icon), like `Session.actions` |
| R3 | Bluetooth icon ×2 | `Bluetooth.qml:66`, `Dashboard.qml:78` | `Bluez.icon` |
| R4 | MediaCard's `compact` layout: nothing sets `compact` | `MediaCard.qml:15, 23, 57-138` | delete (~85 lines) |
| R5 | Functions nothing calls | `Audio.nextSink` (`Audio.qml:48-51`), `Players.pickNext` (`Players.qml:25-28`; its comment names a button that's gone), `Desktops.iconOf` (`Desktops.qml:198-204`) | delete. Or keep `iconOf` as the one app-icon lookup: the same lookup is written out again in `Audio.qml:76-80` and `WindowPreview.qml:85` |
| R6 | StatusGroup's `showText` and `maxWidth`: never set, so `textWidth` is always `maxText` | `StatusGroup.qml:15, 18, 75-79, 98` | drop both properties; `textWidth` → `maxText` |
| R7 | Switcher guard already covered by priorities | `Triggers.qml:50` | delete: a pinned view (2) always beats the switcher (1), which never queues (`machine.test.js:318` proves it). Line 49 stays until I1 |
| R8 | `x` in `pinShown()` is always `undefined` | `Bar.qml:104-105` | a toast is always centred (`toast()` passes no `x`), so `Engine.open(Registry.get(Engine.view)?.opens ?? Engine.view)` |
| R9 | Hover/press layer written by hand ×3 | `Chip.qml:27`, `Tabs.qml:132`, `WorkspaceButtons.qml:96` | `Config.layer(hovered, pressed)` returning `Qt.rgba(text, .12/.08/0)`. Not `Config.state()` with a transparent base: that mixes the RGB too and is a shade lighter |
| R10 | Identical `Label` component ×2 | `Settings.qml:19`, `Theme.qml:26` | `components/SectionLabel.qml` |
| R11 | Battery colour ladder ×2 (only the fallback differs) | `Battery.qml:13-15`, `StatusGroup.qml:57-60` | `Config.levelColor(fallback)`, or a `levelColor` on one side used by the other |
| R12 | View → name ×3; screen lookup ×2 | `Ipc.qml:80, 90`, `Debug.qml:27` · `Debug.qml:34-38` vs `Engine.resolveScreen` | `Registry.name(v)`; Engine exposes the active screen object, and Debug uses it |
| R13 | "something is playing" ×2 | `Compact.qml:17`, `Dashboard.qml:23` | `Players.hasTrack` |
| R14 | `[` `]` brightness keys ×2 | `Dashboard.qml:115-123`, `Battery.qml:19-25` | fine as is (two views, different key sets); revisit if a third view wants them |

Looked at and left alone: the workspace views already share `Desktops.shown`, and component knobs
nobody sets yet (`Header.showBack`, `Segmented.showCheck`, `SearchBar.readOnly`) are reasonable API.

## Docs drift

- **D1.** README's Layout puts `overview/` and `parts/` under `island/` (lines 62-63). They are
  `modules/overview/` and `modules/parts/` now. The configuration table's
  `views/overview/OverviewConfig.qml` (line 135) is `modules/overview/OverviewConfig.qml`.
- **D2.** `state-machine.md:99`: see I3.
- **D3.** `architecture.md:142` (Enter, Space: "handled by the control") and the paragraph after
  the table: rewrite once B1 lands.

## Suggested order

1. B2–B4: one `Machine.js` change plus the four tests. Run `node modules/tests/machine.test.js`.
2. B1: ViewLoader plus the components. Run `tst_keyboard.qml`, and add a case asserting that
   Return, Space and Left/Right on a slider emit `activity()`.
3. The deletions (R4–R8): no behaviour involved.
4. The service properties (R1–R3, R13), then the rest.
5. I1–I3 are behaviour choices, so decide those before touching them.
