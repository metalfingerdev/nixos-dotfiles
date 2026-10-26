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
2. **overlay**: full-screen, on `WlrLayer.Top`, namespace `quickshell:island`, active screen only, reserves
   nothing. Its input mask follows the phase:
   - normally only the **proxy** rect, so the rest of the screen stays clickable;
   - the **whole screen** while a view is Pinned: a click anywhere outside the island closes it;
   - **nothing** while Hidden: the strip handle is only a hint, the spacer's hot zone reveals.
   - Keyboard: while `Engine.keyboard` (a view is Pinned, or the peek view is showing) the overlay takes
     exclusive keyboard focus (`WlrKeyboardFocus.Exclusive`). See [Keyboard and hover](#keyboard-and-hover).

## Bar: the proxy/surface morph

```
Loader item ──implicit size──► proxy (invisible, snaps instantly, the truth)
                                 └──► sx/sy/sw/sh (springs) ──► surface (visible)
```

- **proxy** is an invisible `Item` placed at the island's *final* rect:
  - size = the loaded view's `implicitWidth/Height`, held across view swaps so it never collapses to 0
  - x = `abscissa(width, anchor)`: centred on the click x (or the screen), clamped to `edgePad`.
    `anchor` is `Engine.anchorX`, but taken only when the swap loads the view it belongs to (see View swaps)
  - y = `gap` from the top (0 in notch style), or above the screen when `Engine.hidden`; with the strip
    handle, a `stripW` x `stripH` bar at the top edge instead

  It is never animated, so the input mask is correct on the first frame.
- Any change to the proxy's x/y/width/height is coalesced with `Qt.callLater(snap)`. `snap()`
  assigns the proxy rect to `sx/sy/sw/sh`. Each has a `Behavior` with a `SpringAnimation` (`stiffness`,
  `damping`). A redirect mid-flight keeps the current velocity, but restarting the animation stalls it
  for a frame or two, so Bar avoids redirects it can see coming (see View swaps).
- The Behaviors are enabled only while `armed`, so the same assignment jumps instead of springing.
  `disarm(ms)` turns them off for a while: 500 ms at startup (so the
  window going from 0 to its real size doesn't animate in) and 150 ms when a Bar becomes the active one.
- **surface** is the visible `Rectangle`, drawn at `sx/sy/sw/sh` with `clip: true`. Its size is
  clamped at 0, because a spring can undershoot. Its corners come from `Config`: `min(height / 2,
  Config.radius)` (so low shapes are capsules), and a square top in notch style, where two
  **anti-corners** (Shapes outside the surface, from the same sprung rect) curve it into the screen
  edge. With `Config.glass` the colour is translucent, a 1 px rim lights its edge, and Bar asks Hyprland to
  blur the layer (`Desktops.blurLayer`).
- A click on the surface's own background (under the view's controls), `pinShown()`: a toast opens its
  full view, the Registry's `opens` (the workspace dots open the overview, the volume and brightness
  toasts the dashboard), or else its own view, Pinned; the clock (Compact, at rest) and the glance
  (Expanded, peeking or pinned) open the hub, `Tabs`. Elsewhere it does nothing.
- **Privacy dots** sit beside the surface while `Privacy.microphone` / `Privacy.camera` is true.
- The **Loader** inside the surface (`ViewLoader.qml`) is always the view's *final* size. As the surface grows, it reveals
  the content instead of squashing it. It is centred horizontally (or pinned to its final screen position
  when `pinView` is true).

### View swaps

When `Engine.view` changes, `swap` fades the loader out (90 ms), sets `shown = target` (the Loader loads
the new file, which resizes the proxy and starts the morph), then fades in (140 ms).

The swap also takes the new `Engine.anchorX` at that moment, not when it changes, so x, width and height
all start together once the view is in. If x started first, the load (synchronous, tens of ms for a
list view) and the new size's redirect would land mid-slide and the island would visibly stutter.

### Keyboard and hover

| | Peek (hover) | Pinned (click, IPC) | Rest, Toast, Hidden |
|---|---|---|---|
| keyboard | yes | yes | never, so a toast can't steal typing from an app |
| hover | the view lives as long as the hover (plus `graceMs`) | pauses the countdown; leaving restarts it | holds a toast; at Rest, starts the peek |
| keystroke | nothing (no countdown) | restarts the countdown from the top | - |

The peek key (IPC `peek true`/`peek false`, see [ipc.md](ipc.md)) calls `Engine.peek(on)`: it shows the
rest view while held (revealing it from Hidden) and, in auto-hide mode, hides it at once on release. The
rest view doesn't take the keyboard. `Engine.togglePeek()` (IPC `togglePeek`) is the one-binding version:
`peek(!Engine.peeking)`.

A `HoverHandler` on the overlay's root item reports `Engine.hover(on)` while the pointer is inside the
**proxy** rect, the same final rect the input mask uses. It used to sit on the surface, but a spring
overshoots: a notch revealed from auto-hide dips a pixel below the top edge, out from under a pointer
resting there, and the peek would collapse and reopen until the spring settled. It's on the root item
because Qt stops hover at the first sibling that takes it, while ancestors always get it.

`ViewLoader` is a focus scope with the default keys. A key goes to the focused item and bubbles up
through the view, and whatever the view doesn't accept reaches the defaults:

| Key | Default |
|---|---|
| Tab / Backtab | next / previous item with `activeFocusOnTab` in the view, wrapping |
| arrows | the nearest focusable item that way, by screen position (so grids work); nothing that way: next (Right/Down) or previous (Left/Up), wrapping |
| a letter, digit or sign | presses the control whose `shortcut` it is (shown as a keycap while the keyboard is in use) |
| Enter, Space | press the focused control (handled by the control) |
| Escape | `cancel()`, which Bar maps to `Engine.close()`: everything closes, back to the clock |
| Backspace | `back()`, which Bar maps to `Engine.back()`: the view that was open before (closes when there is none). The mouse's back button does the same, anywhere on the island or outside it |

Every key that reaches `ViewLoader`, and every focus move inside the view, emits `activity()`, which Bar
maps to `Engine.key()`. Keys a view accepts itself never reach it, so such a view calls `Engine.key()`
itself (the launcher's field does, in `Keys.onPressed`).

The same, minus the focus a view takes as it loads (`settleMs`), emits `navigated()`, which turns on
`Config.focusVisible`; so does `Ipc.open` (a view opened over IPC is a keybind). The pointer *moving*
over the island turns it off: Bar compares positions, because Qt re-sends hover every frame something
animates under a still pointer. While it is on, components draw a `FocusRing` (3 px, just outside the
control, in the primary colour) and their `KeyBadge`, and views show their `KeyHints` footer; a view
opened with the mouse shows none of them.

Bar draws the view slot at `Config.scale` (Theme's Size): the proxy takes the view's implicit size
times the scale, and `ViewLoader` is laid out at 100 % with a `scale` transform, so views know nothing
about it.

On load, the item the view marked `focus: true` gets focus, else the first focusable one. `ViewLoader`
is plain QtQuick (no `Engine`), so `modules/tests/tst_keyboard.qml` tests it with real key events.
