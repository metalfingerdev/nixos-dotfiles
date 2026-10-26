# Architecture

## Layers

| Layer | File | Knows about | Must not know about |
|---|---|---|---|
| Logic | `Machine.js` | phases, events, the `cfg` callbacks | QML, timers, the clock, the screen |
| Engine | `Engine.qml` | the snapshot, the one `Timer`, `Registry` (via `config()`) | pixels, windows |
| Data | `Registry.qml` | view names, priorities, timeouts, files | behaviour |
| Presentation | `Bar.qml`, `views/*` | `Engine`'s read-only properties, `Registry` URLs | how decisions are made |
| Input adapters | `Ipc.qml`, `Triggers.qml` | strings / system services → `Engine` calls, plus facts about the event (e.g. "critical", mapped to a priority by `Registry`) | priority rules, timing, queueing |

Keep it this way: behaviour goes in `Machine.js`, per-view settings go in `Registry.qml`, and everything
else turns input into one `Engine` call or turns `Engine` state into pixels.

## Engine

`Engine` is a singleton `QtObject`:

- `snapshot` is the only mutable state. `send(event)` replaces it with `Machine.reduce(snapshot, event, config())`.
- If `snapshot.timer` changes identity, `arm()` restarts the single `Timer` with `timer.ms`, or stops it when
  the timer is `null`. When it fires, `Engine` sends `Expire`.
- Read-only properties (`view`, `phase`, `hidden`, `pinned`, `keyboard`, `hovered`, `autoHide`, `anchorX`)
  are what the UI binds to.
- The public API is one function per event: `open(v, x?)`, `close()`, `back()`, `alert(v, priority?)`,
  `hover(on)`, `edge(on, screenName)`, `setAutoHide(on)`, `key()`.
- `debug` is a plain setting (not machine state). It shows `Debug.qml`'s overlay and Bar's proxy box.

### Screens

The machine knows nothing about screens. `Engine` keeps `screenName` and exposes `activeScreen` (an empty
or unplugged name falls back to the first screen). `setScreen(name)` moves the island and sends `Leave`,
since the old surface is gone. `edge(true, name)` also moves the island to that screen, but only while it
is Hidden or at Rest, so an open view never jumps away. `screens()` lists the names.

## Bar: windows

`shell.qml` creates one `Bar` per screen (`Variants { model: Quickshell.screens }`). `Ipc` and `Triggers`
are created once in `shell.qml`, not per Bar. All Bars share the `Engine`, and `Bar.active` is
`Engine.activeScreen === screen.name`. Only the active Bar shows the island; inactive Bars keep only the
auto-hide hot zone, and their Loader is inactive, so a view (for example the launcher's text field) exists
on one screen only.

Each `Bar` creates two layer-shell `PanelWindow`s:

1. **spacer**: a full-width strip at the top.
   - With auto-hide off, it exists on the active screen only. It is `space` px tall and reserves that
     space (`ExclusionMode.Auto`), so tiled windows stay below the island. Input passes through it.
   - With auto-hide on, it exists on **every** screen. It is `hotZone` px tall, reserves nothing, and its
     input mask is the strip. Hovering the strip sends `Engine.edge(true/false, screen)`
     (`Reach`/`Retreat`), which can also move the island to that screen.
2. **overlay**: full-screen, on `WlrLayer.Top`, active screen only, reserves nothing. Its input mask is
   only the **proxy** rect, so the rest of the screen stays clickable.
   - Keyboard: while `Engine.keyboard` (a view is Pinned, or the peek view is showing) the overlay takes
     exclusive keyboard focus (`WlrKeyboardFocus.Exclusive`). See [Keyboard and hover](#keyboard-and-hover).

## Bar: the proxy/surface morph

```
Loader item ──implicit size──► proxy (invisible, snaps instantly, the truth)
                                 └──► sx/sy/sw/sh (springs) ──► surface (visible)
```

- **proxy** is an invisible `Item` placed at the island's *final* rect:
  - size = the loaded view's `implicitWidth/Height`, held across view swaps so it never collapses to 0
  - x = `abscissa(width, Engine.anchorX)`: centred on the click x (or the screen), clamped to `edgePad`
  - y = `gap` from the top, or above the screen when `Engine.hidden`

  It is never animated, so the input mask is correct on the first frame.
- Any change to the proxy's x/y/width/height is coalesced with `Qt.callLater(snap)`. `snap()`
  assigns the proxy rect to `sx/sy/sw/sh`. Each has a `Behavior` with a `SpringAnimation` (`stiffness`,
  `damping`). A redirect mid-flight keeps the current velocity, so the island never lurches.
- The Behaviors are enabled only while `armed`, so the same assignment jumps instead of springing.
  `disarm(ms)` turns them off for a while: 500 ms at startup (so the
  window going from 0 to its real size doesn't animate in) and 150 ms when a Bar becomes the active one.
- **surface** is the visible rounded `Rectangle`, drawn at `sx/sy/sw/sh` with `clip: true`. Its size is
  clamped at 0, because a spring can undershoot.
- The **Loader** inside the surface (`ViewLoader.qml`) is always the view's *final* size. As the surface grows, it reveals
  the content instead of squashing it. It is centred horizontally (or pinned to its final screen position
  when `pinView` is true).

### View swaps

When `Engine.view` changes, `swap` fades the loader out (90 ms), sets `shown = target` (the Loader loads
the new file, which resizes the proxy and starts the morph), then fades in (140 ms).

### Keyboard and hover

| | Peek (hover, peek key) | Pinned (click, IPC) | Rest, Toast, Hidden |
|---|---|---|---|
| keyboard | yes | yes | never, so a toast can't steal typing from an app |
| hover | the view lives as long as the hover or the peek key (plus `graceMs`) | pauses the countdown; leaving restarts it | holds a toast; at Rest, starts the peek |
| keystroke | nothing (no countdown) | restarts the countdown from the top | - |

The peek key (IPC `peek true`/`peek false`, see [ipc.md](ipc.md)) is hover from the keyboard: it calls
`Engine.peek(on)`, opens the peek straight from Rest or Hidden, and holds it the way the pointer does.

A `HoverHandler` on the **surface** reports `Engine.hover(on)`. Because the surface animates, hover follows
what you see, while clicks follow the proxy mask.

`ViewLoader` is a focus scope with the default keys. A key goes to the focused item and bubbles up
through the view, and whatever the view doesn't accept reaches the defaults:

| Key | Default |
|---|---|
| Tab, Right, Down | next item with `activeFocusOnTab` in the view, wrapping |
| Backtab, Left, Up | previous |
| Enter, Space | press the focused `Pill` (handled by `Pill`) |
| Escape | `cancel()`, which Bar maps to `Engine.back()` (closes when there is no history) |

Every key that reaches `ViewLoader`, and every focus move inside the view, emits `activity()`, which Bar
maps to `Engine.key()`. Keys a view accepts itself never reach it, so such a view calls `Engine.key()`
itself (the launcher's field does, in `Keys.onPressed`).

On load, the item the view marked `focus: true` gets focus, else the first focusable one. `ViewLoader`
is plain QtQuick (no `Engine`), so `modules/tests/tst_keyboard.qml` tests it with real key events.
