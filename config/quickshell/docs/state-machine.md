# State machine (`Machine.js`)

`reduce(state, event, cfg) -> state` is a pure function. States are plain objects and are never mutated
(`set()` copies). Nothing in this file touches QML, timers or the clock, so it can be tested with plain JS.

## State

| Field | Meaning |
|---|---|
| `phase` | `hidden` · `rest` · `peek` · `pinned` · `toast` |
| `view` | the `Engine.View` currently shown |
| `prio` | the priority of what is showing: the alert's own if it brought one, else the view's |
| `hovered`, `edge`, `peeking` | "holding" facts: the pointer is on the island, or in the top-edge hot zone, or the peek key is held. Any one pauses countdowns |
| `peeking` | the peek key is held (IPC `peek true` until `peek false`). Only ever true at Rest: `enter()` clears it |
| `x` | anchor in window coords: the x to centre on (the click), `-1` = the screen centre. The island always hangs from the top |
| `ms` | the current phase's countdown length (0 = none) |
| `timer` | `{ ms, kind }` or `null`. `kind` is `hold` (phase countdown), `intent` (hover) or `grace` (peek). The engine re-arms its Timer when this object changes identity |
| `history` | stack of `{ view, x, priority }` for Back |
| `autoHide` | auto-hide mode |
| `queued`, `queuedPrio` | one waiting alert view and its priority, or `-1` |

## Phases

| Phase | What it is | Countdown |
|---|---|---|
| Hidden | parked above the screen (auto-hide only); the top-edge hot zone reveals it | none |
| Rest | `restView` (Compact), also shown while the peek key is held | `hideMs` in auto-hide mode, otherwise none; releasing the peek key hides at once |
| Peek | `peekView`, shown because of hover | none; `graceMs` after the pointer leaves |
| Pinned | a view opened by click or IPC | the view's `Registry.timeout`, restarted by each keystroke |
| Toast | a view raised by the system (`alert`) | the view's `Registry.timeout` |

## Events

Pointer and mode events (`hover` `leave` `reach` `retreat` `mode`) first update the holding facts and
`autoHide` in **every** phase (`track()`), and then the phase may react. The others are `peek` `unpeek`
`open` `close` `back` `alert` `key` `expire`.

Hover holds, the keyboard restarts:

- **Hover** pauses a countdown for as long as the pointer is on the island, and leaving starts it again.
- **`peek` / `unpeek`** are the peek key's press and release: they show the rest view while the key is
  held. From Hidden, `peek` reveals Rest (`reveal()`); at Rest it holds it there (`keep()`). Either way
  it sets `peeking`, which holds the linger the way `hovered` does. `unpeek` (`release()`) clears it
  and, in auto-hide mode, hides at once, unless the pointer is still on the island or at the edge (then
  letting go of that starts the usual linger). A running hover intent is left alone, so hovering while
  the key is held still peeks. `release()` does nothing unless `peeking` is set, so releasing a key
  that was pressed in another phase can't cut a linger short. `enter()` clears `peeking` on every
  phase change, so a release that never arrives can't hold anything afterwards. The key is ignored
  while Peek, Pinned or Toast.
- **`key`** is any keystroke in the island. It only matters while Pinned: `start()` gives a fresh
  countdown from the top (still none while hovered). The peek view has the keyboard too, but it has no
  countdown: it lives exactly as long as the hover.

## Transition table

| Phase \ Event | hover | leave | reach/retreat | peek | unpeek | open | close | back | alert | key | mode | expire |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Hidden** | | | reach → Rest | reveal → Rest | | → Pinned | | | → Toast | | unhide | |
| **Rest** | intent | rearm | rearm | keep | release (→ Hidden) | → Pinned | | | → Toast | | retime | lapse |
| **Peek** | (cancels grace) | letGo | | | | → Pinned | → Rest | → Rest | → Toast | | | → Rest |
| **Pinned** | rearm | rearm | rearm | | | toggle | → Rest | goBack | alertPinned | start | | → Rest |
| **Toast** | rearm | rearm | rearm | | | → Pinned | toastEnd | toastEnd | alertToast | | | toastEnd |

Empty cells: the event only updates the tracked facts.

`open` of the rest view never pins it (it has no timeout, so it would never close): it goes to Rest, the
same as `close`. Alerts of the rest view are ignored (`usable()`).

## Timers

There is one rule (`wanted()`): a timer runs only in a timed phase (Rest, Pinned, Toast), with `ms > 0`,
while nothing is holding.

- `start()` applies the rule with a **new** timer object, so the countdown restarts. `enter()` uses it, so
  every phase change (including a refreshed toast, or a different view with the same timeout) counts down
  from the top. A keystroke while Pinned calls it directly.
- `rearm()` applies the rule after a holding fact may have changed. If the timer that is already running is
  the one still wanted (same `kind` and `ms`), it keeps that very object, and `Engine` leaves its Timer
  alone. So an unrelated `leave` or `retreat` doesn't restart the countdown. Hovering a pinned
  view still pauses it, and leaving restarts it.
- `expire` sets `timer` to `null` in `track()`, so a spent object is never reused.

Two other timers are set directly:

- **hover intent** (Rest, `hoverMs`, kind `intent`): `lapse()` tells it apart from the linger timer by
  checking `hovered`.
- **grace** (Peek, `graceMs`, kind `grace`): started by `letGo()` when the pointer leaves the peek. A new
  `hover` cancels it in `track()`.

Because `rearm()` compares `kind`, an intent or grace timer is never mistaken for the countdown just
because the durations match.

## History (Back)

- Opening from Peek or Pinned pushes the current `{view, x, priority}`. Opening from Rest or Hidden starts with an
  empty history (`trail()`).
- `back` pops the top entry and restores it as **Pinned**, with its anchor. If the history is empty, back
  closes the island.
- Opening the view that is already pinned closes it (`toggle`).
- Opening the view that is peeking (a click on the peek) pins it without stacking it: the history stays
  as it was, so Back doesn't show the same view twice.

## Alerts, priority and the queue

Each Registry entry has `priority` and optionally `queue: true`.

**Priority belongs to the alert, not the view.** An `alert` event may carry its own `priority`. Without
one, it gets `cfg.priority(view)`. Whatever enters the screen records its priority in `prio`. History
entries and the queue carry it too, so an urgent alert stays urgent while it waits and when Back
restores it. `open` is the user's choice, not an alert, so a pinned view always has the view's own
priority. This way one view can be urgent sometimes: a critical notification is the Notifications view
alerted at its Registry `critical` priority, not a separate view. Every comparison below uses these
priorities, never `cfg.priority(view)` of what is on screen.

- **From Hidden, Rest or Peek**: the toast is shown and leaves no history.
- **Over Pinned** (`alertPinned`): the toast interrupts only if its priority is *higher* and the user isn't
  holding the island. The pinned view is pushed onto history, so it comes back afterwards. Otherwise the
  alert is parked.
- **Over a Toast** (`alertToast`): the same view refreshes the countdown and keeps the *higher* of the two
  priorities (what it shows now includes the urgent thing). Equal or higher priority replaces the current
  toast, and the replaced toast is parked (with its priority) if it may queue. Lower priority is parked.
- **Parking** (`park`) keeps one slot. Only views with `queue: true` are kept. The highest priority wins,
  and the newer alert wins a tie. The same view parked again keeps the higher priority.
- **Delivery**: every route back to Rest (`toRest`, `toastEnd`) shows the parked alert first. A delivered
  toast returns to Rest, not to whatever was open before.
- **When a toast ends** (`toastEnd`): go back through history if there is one, else deliver the parked
  alert, else go to Hidden (auto-hide) or Rest.

## Watching it live

Run `qs ipc call island debug true` (or `toggleDebug`). A click-through overlay at the bottom left of the active screen shows
the phase, view, anchor, holding facts, queue, history, and the running timer (its kind, the ms left,
and a bar). "PAUSED (held)" means the phase has a countdown but something is holding it. Bar also draws the proxy (the
island's final rect, and its input mask) as a translucent green box.

For a one-off look, or from a script, `qs ipc call island dump` prints the same snapshot as JSON.

## Changing the machine

- New behaviour = a new handler function plus a table entry. Keep handlers `(s, e, cfg) -> s` with no
  side effects.
- All phase changes go through `enter()`, which applies the anchor rule and restarts the timer.
- Anything the machine needs to know about a view comes in through `cfg` (see `Engine.config()`). Don't
  read `Registry` from `Machine.js`.
- Run `node modules/tests/machine.test.js` before and after changing it, and add a case for the path
  you changed. The harness loads the file (minus `.pragma library`) into a `vm` context and replays event
  sequences against a fake `cfg` that mirrors `Registry.qml`.
