# island

A Dynamic-Island-style top bar for [Quickshell](https://quickshell.outfoxxed.me/). The island is a single
rounded surface that morphs between views (a clock, a hub, detail panels, toasts), driven by
a small pure state machine. It is drawn in Material 3, the way Android's quick settings are: tonal
surfaces, pill tiles with an icon circle, thick pill sliders, segmented buttons, sentence-case type.

How you move through it:

```
Compact (rest) ──pointer on the island──► Expanded (only while it's there)
   clock + live                              time, what's on, what's playing
   indicators
      │                                         │
      └───────────────── click ─────────────────┴──► Tabs (the hub) ──► any view
                                                       clock, workspaces, one tab per view,
                                                       status (each segment opens its view, the group the dashboard)

Backspace, the mouse's back button, ← ──► the view that was open before
Escape, a click outside, a timer      ──► home (the clock)
```

> **Status:** prototype. The morphing surface (pill or notch, on Hyprland's frosted glass), hover/peek,
> pinning, back-history, auto-hide, IPC, multi-monitor, and every view work: the hub (tabs), the
> dashboard, launcher, network, bluetooth, media, the volume mixer, notifications, workspace overview,
> clock, battery, power, theme and wallpaper, settings, plus toasts (volume, brightness, notifications, battery,
> workspace switch) and privacy dots.
> See [docs/roadmap.md](docs/roadmap.md) and [docs/old-shell-notes.md](docs/old-shell-notes.md).

## Running

```sh
qs -p /path/to/this/folder
```

`shell.qml` is the entry point. It creates one `Ipc`, one `Triggers`, and one `Bar` per screen, plus
the lock screen (`Lock`, locked with `qs ipc call lock screen`) and the `ActivateLinux` text in each corner.

## Tests

```sh
node modules/tests/machine.test.js                                         # the state machine
QT_QPA_PLATFORM=offscreen qmltestrunner -input modules/tests/tst_keyboard.qml   # default keyboard
qs -p lock-test.qml                                                        # the lock screen, in a window
```

`machine.test.js` replays event sequences against `Machine.js`, with the view list and the Registry read
from `Engine.qml` and `Registry.qml` themselves. `tst_keyboard.qml` sends real key events to `ViewLoader`
and the controls.

## Layout

```
shell.qml                     entry point: Ipc, Triggers, Variants { Bar } (one per screen), Wallpaper,
                              Lock, ActivateLinux
lock-test.qml                 the lock surface in a normal window, nothing locked (at the root, or `qs.*` won't resolve)
modules/
  lock/
    Lock.qml                  the session lock: a LockSurface per screen, `qs ipc call lock screen`
    LockContext.qml           what's typed and PAM, shared by every screen's surface
    LockConfig.qml            what the lock shows (a singleton: IPC and views/Settings.qml set it)
    LockSurface.qml           the picture; the clock top left, the avatar and name top right, the password field along the bottom
    Idle.qml                  hypridle's job, a singleton: dim, lock, screens off, suspend; the lock before sleep
    pam/password.conf         PAM for the lock: pam_unix (the password only)
  activatelinux/
    ActivateLinux.qml         a click-through text OSD in each screen's bottom-right corner
  island/
    Machine.js                pure statechart: reduce(state, event, cfg) -> state
    Engine.qml                singleton: holds the snapshot, owns the one Timer, public API
    Registry.qml              singleton: every view's name, priority, timeout, queue flag, QML file
    Bar.qml                   per screen: the windows, the proxy/surface morph, the look (pill/notch,
                              anti-corners, handle; the glass layer), outside-click close, privacy dots
    ViewLoader.qml            the view slot: a Loader plus the default keyboard
    Ipc.qml                   `qs ipc call island ...` commands
    Triggers.qml              system events -> alerts (volume, brightness, battery, media, workspace switch)
    Debug.qml                 live snapshot overlay, toggled with `qs ipc call island debug true`
    views/                    one QML file per view: Compact Expanded Tabs Dashboard Launcher Network Bluetooth
                              Media Mixer Notification Workspaces Clock Battery Power Theme (with the
                              full Colours and Wallpapers) Settings, and the toasts Volume Brightness
                              Switcher
  overview/                   the Workspaces overview's tiles, live previews, special strip, options
  parts/                      pieces several views share: WorkspaceDots (GNOME-style), StatusGroup (what's
                              on, as a button group), MediaCard, NotificationCard, WallpaperThumb,
                              VolumeSlider, BrightnessSlider, DateStamp
  services/                   system state, no island logic: Audio, Backlight, Notifier, Net (Wi-Fi),
                              Bluez, Players (MPRIS), Energy (battery), Session (power), Desktops
                              (Hyprland), Toplevels, Privacy (mic/camera), Wallpaper (awww), Toggles
                              (caffeine, night light, recording, airplane, power profiles, screenshots)
  components/
    Config.qml                singleton: Material 3 palettes, shape, type; remembered across restarts
    Pill.qml                  button: tonal, filled or text; round when it's only an icon
    QuickTile.qml             a quick settings tile (icon circle, label, state; optionally split)
    Slider.qml                a thick pill slider (the fill carries the icon)
    Segmented.qml Chip.qml SearchBar.qml Toggle.qml (switch) Header.qml (top app bar)
    Icon.qml                  a Material Symbols glyph
    Swatch.qml                a round colour to pick (or a palette: its surface around its primary)
    ColourMap.qml             every colour: hue and lightness on a map, washed by a saturation
    ListEntry Tile ScrollList Progress Equalizer CalendarGrid
    Label ClickArea CoverImage SectionLabel   a Text, MouseArea and Image with the island's usual settings
    Store.qml                 Settings in the one state file (~/.local/state/quickshell/island.ini)
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
| | `peekView` | `Expanded` | view shown when the pointer is on the resting island's surface (not at the top edge); `-1` turns peeking off. The peek key shows the rest view instead |
| | `hoverMs` | 140 | hover delay before peeking |
| | `graceMs` | 140 | how long a peek stays after the pointer leaves |
| | `hideMs` | 700 | auto-hide: how long the island lingers before hiding |
| | initial `autoHide` | `true` | second argument to `Machine.initial(...)` |
| `Config.qml` | `source` | `preset` | where colours come from: `preset`, `accent` or `wallpaper`; IPC `colours` |
| | `name` | `teal` | preset palette (teal blue graphite midnight nord rose forest paper); IPC `palette` |
| | `accent` / `tint` / `darkMode` | / `0.5` / `true` | a generated scheme: its colour, how much of it the surfaces take (0..1), dark or light; IPC `accent` `tint` `mode` |
| | `wallpaperSaturation` / `wallpaperTone` | `0.8` / `0.72` | how the wallpaper colour's hue becomes a primary |
| | `scale` | 1.0 | the whole island's size (0.8 .. 1.4); IPC `size` |
| | `style` | `pill` | `pill` floats below the edge; `notch` is flush with it, with anti-corners; IPC `style` |
| | `handle` | `strip` | auto-hide: a thin bar stays at the top edge while hidden (`none`: nothing); IPC `handle` |
| | `radius` | 28 | the island's largest corner (Material's extra large); lower shapes are capsules |
| | `curve` / `motionMs` | `[0.22, 1, 0.36, 1]` / 350 | the morph's ease-out (`Motion`), never overshooting; the same as Hyprland's windows (`Glide` in hypr/modules/look.lua, speed 3.5), so change both together. The workspace buttons in Tabs move with it, so they stay with the island's edge |
| `hypr/modules/look.lua` | `active_opacity` / `inactive_opacity`, `blur`, layer rule `glass` | 0.8 | the glass: every window at 80 % over a frosted blur; layers named `glass` or `glass:*` (the island is `glass:island`) get the blur, and the island takes `active_opacity` too (`Desktops.windowOpacity`, re-read on `hyprctl reload`) |
| `Bar.qml` | `gap` / `edgePad` | 8 (notch: 0) / 8 | distance from the top edge / from the screen sides |
| | `space` | `gap` + 36 | height reserved at the top when auto-hide is off |
| | `hotZone` | 4 | height of the top-edge strip that reveals the island |
| | `debug` | `Engine.debug` | draws the proxy as a translucent green box |
| | `pinView` | `false` | content stays put while the surface slides over it |
| `Registry.qml` | per view | | `priority`, `critical`, `timeout` (ms, 0 = none), `queue` |
| `Engine.qml` | `screenName` | `""` | screen that shows the island (`""` or an unplugged screen = the first) |
| `Notifier.qml` | `lowMs` / `normalMs` / `criticalMs`, `maxPopups` | 10000 / 10000 / 0, 3 | dunst-style popup timing |
| `Triggers.qml` | `followFocus` | `true` | the idle island moves to the monitor Hyprland focuses |
| | `switcherToasts` | `true` | switching workspace shows GNOME-style dots (`views/Switcher.qml`) |
| `Notifier.qml` | `dnd` | `false` | Do not disturb: only critical notifications pop up; remembered |
| `Toggles.qml` | `warmth` | 4500 | night light colour temperature (K), via hyprsunset; remembered |
| `Energy.qml` | `lowAt` / `criticalAt` | 15 / 5 | battery warnings (a toast; critical interrupts) |
| `Wallpaper.qml` | `dir`, `transition`, `duration` | `~/Pictures/Wallpapers`, fade, 0.8 | awww |
| `modules/overview/OverviewConfig.qml` | `rows` / `columns`, `previewMode`, ... | 2 / 5, live | the workspace overview |
