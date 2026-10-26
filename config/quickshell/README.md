# island

A Dynamic-Island-style top bar for [Quickshell](https://quickshell.outfoxxed.me/). The island is a single
rounded surface that morphs between views (a clock, a quick-actions row, detail panels, toasts), driven by
a small pure state machine.

> **Status:** prototype. The morphing surface, hover/peek, pinning, back-history, auto-hide, IPC,
> multi-monitor, the app launcher and system-event toasts (volume, brightness, notifications) work.
> Network and Bluetooth are placeholders. See [docs/roadmap.md](docs/roadmap.md).

## Running

```sh
qs -p /path/to/this/folder
```

`shell.qml` is the entry point. It creates one `Ipc`, one `Triggers`, and one `Bar` per screen.

## Tests

```sh
node modules/tests/machine.test.js                                         # the state machine
QT_QPA_PLATFORM=offscreen qmltestrunner -input modules/tests/tst_keyboard.qml   # default keyboard
```

`machine.test.js` replays event sequences against `Machine.js` with a fake Registry. Keep its `REG` table
in sync with `Registry.qml`. `tst_keyboard.qml` sends real key events to `ViewLoader` and `Pill`.

## Layout

```
shell.qml                     entry point: Ipc, Triggers, Variants { Bar } (one per screen)
modules/
  island/
    Machine.js                pure statechart: reduce(state, event, cfg) -> state
    Engine.qml                singleton: holds the snapshot, owns the one Timer, public API
    Registry.qml              singleton: every view's name, priority, timeout, queue flag, QML file
    Bar.qml                   per screen: the windows, the proxy/surface morph
    ViewLoader.qml            the view slot: a Loader plus the default keyboard
    Ipc.qml                   `qs ipc call island ...` commands
    Triggers.qml              system events -> alerts
    Debug.qml                 live snapshot overlay, toggled with `qs ipc call island debug true`
    views/                    one QML file per view
  services/                   Audio, Backlight, Notifier singletons (system state, no island logic)
  components/
    Pill.qml                  shared pill button (focusable; Enter/Space press it)
    Meter.qml                 shared level bar
  tests/
    machine.test.js           Node tests for Machine.js
    tst_keyboard.qml          qmltestrunner tests for the default keyboard
```

## How it fits together

```
input (hover, clicks, IPC, system events)
        │
        ▼
Engine.open/close/back/alert/hover/key/...  ──►  Machine.reduce(snapshot, event, cfg)
        │                                              │
        │                           new snapshot ◄─────┘   (phase, view, anchor, timer, history, queue)
        ▼
Bar: Loader shows Registry.get(view).url
     proxy snaps to the view's size/position  ──►  surface animates onto it
```

- [docs/architecture.md](docs/architecture.md): the layers, and how the proxy/surface morph works
- [docs/state-machine.md](docs/state-machine.md): phases, events, timers, history and the alert queue
- [docs/adding-a-view.md](docs/adding-a-view.md): step-by-step guide to adding a view or toast
- [docs/ipc.md](docs/ipc.md): command-line control
- [docs/roadmap.md](docs/roadmap.md): known issues and next steps

## Configuration at a glance

| Where | Property | Default | Meaning |
|---|---|---|---|
| `Engine.qml` | `debug` | `false` | debug overlay + proxy box; IPC `debug` / `toggleDebug` |
| | `peekView` | `Expanded` | view shown when you hover the resting island; `-1` turns peeking off. The peek key shows the rest view instead |
| | `hoverMs` | 140 | hover delay before peeking |
| | `graceMs` | 140 | how long a peek stays after the pointer leaves |
| | `hideMs` | 700 | auto-hide: how long the island lingers before hiding |
| | initial `autoHide` | `true` | second argument to `Machine.initial(...)` |
| `Bar.qml` | `gap` / `edgePad` | 8 / 8 | distance from the top edge / from the screen sides |
| | `space` | 42 | height reserved at the top when auto-hide is off |
| | `hotZone` | 4 | height of the top-edge strip that reveals the island |
| | `stiffness` / `damping` | 3.2 / 0.34 | morph spring: higher stiffness = snappier, lower damping = more overshoot |
| | `debug` | `Engine.debug` | draws the proxy as a translucent green box |
| | `pinView` | `false` | content stays put while the surface slides over it |
| `Registry.qml` | per view | | `priority`, `critical`, `timeout` (ms, 0 = none), `queue` |
| `Engine.qml` | `screenName` | `""` | screen that shows the island (`""` or an unplugged screen = the first) |
| `Notifier.qml` | `lowMs` / `normalMs` / `criticalMs`, `maxPopups` | 10000 / 10000 / 0, 3 | dunst-style popup timing |
