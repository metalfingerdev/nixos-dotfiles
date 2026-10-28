# Notes from the old shell

`~/Projects/quickshell` is the previous version of this bar (`modules/taskbar`, plus the older
`modules/dynamicGlacier`). It had every view implemented. These are the things it did better, and what
became of them here.

## Ported

| Old file | What it did better | Here |
|---|---|---|
| `services/NetworkManager.qml` | Signal is bucketed before sorting, so the list doesn't reshuffle on every scan | `Net.networks` sorts by connected, then signal quarter, then name |
| | `holdOrder`: the list keeps its order while a password prompt is open | `views/Network.qml` freezes the order while a row is open |
| | A failed first connection leaves a broken profile behind; it is deleted | `Net.connect()` forgets a network that had no profile before the failed attempt |
| | Errors clear themselves after 6 s | `Net.lastError` (`errorMs`) |
| `views/Network.qml` | The prompt stays open while connecting and closes once connected; a failure keeps it open for another try | `views/Network.qml` |
| | Scrollable list instead of a cut-off | Network and Bluetooth lists scroll (`components/ScrollList.qml`) |
| `views/Media.qml` | Keeps the last good length/position per track: players report junk right after a seek or while buffering | `Players.length` / `Players.position` / `Players.canSeek` |
| | Polls the position every 250 ms, not only while "playing" (a wrong state while buffering would freeze the bar) | `Players` |
| `Progress.qml` | Drag to seek (seeks once, on release), thicker on hover, a knob; NaN from a flaky player becomes 0; no width animation (NaN poisons it and the poll keeps restarting it) | `components/Progress.qml` |
| `views/Theme.qml` + `services/Wallpaper.qml` | Wallpaper picker for awww: restores the last wallpaper at login, IPC `wallpaper next/prev/random/set/reload`, thumbnails decoded small | `services/Wallpaper.qml`, a strip in `views/Theme.qml` |
| `views/Compact.qml` + `CavaBars.qml` | Equalizer bars next to the clock while music plays (the island grows for them) | `components/Equalizer.qml`, `views/Compact.qml` |
| `views/Media.qml` (dynamicGlacier) | Shuffle and repeat (off -> track -> playlist); play/pause falls back to play() / pause() for players that can't toggle | `Players`, `views/Media.qml` |
| `views/Workspaces.qml` + `views/workspaces/*` + `services/Workspaces.qml` + `services/Toplevels.qml` | A real overview (after quickshell-overview): monitor-shaped tiles, live window previews, drag a window to another workspace or a special one, middle-click closes, special workspaces strip, arrows/hjkl/1-9, wheel steps workspaces, scales to fit the screen | `views/Workspaces.qml`, `views/overview/*`, `services/Desktops.qml`, `services/Toplevels.qml` |
| `services/Workspaces.qml` | Dispatches in both Hyprland syntaxes (`Hyprland.usingLua`), so empty workspaces and single windows can be targeted | `Desktops.focus()`, `focusWindow()`, `closeWindow()`, `moveWindow*()` |
| `views/Launcher.qml` | App icons, `genericName` matching, terminal apps run in kitty, Backspace on an empty field goes back, the pointer only takes the selection when it actually moves | `views/Launcher.qml`, plus ranking (prefix > word start > substring > in-order letters) |

## The island: old `Bar` + `dynamicGlacier`, merged into `Bar.qml`

The new island keeps its own core (Machine.js, the proxy/spring morph, multi-monitor, ViewLoader's
keyboard). On top of it:

| From | What | Here |
|---|---|---|
| old `Island.qml` | **Pill vs notch**: floating with every corner round, or flush with the top edge with a square top | `Config.style`, Bar's per-corner radii |
| `dynamicGlacier/IslandSurface.qml` | **Anti-corners**: in notch style the island curves into the screen edge | `AntiCorner` in `Bar.qml` |
| `dynamicGlacier/IslandSurface.qml` | The corner follows the height: small shapes (the clock, HUDs) are capsules | `Config.radius`, `min(h / 2, radius)` |
| `dynamicGlacier/DynamicGlacier.qml` + `FrostedGlassSurface.qml` | **Frosted glass**: a translucent surface plus a Hyprland layer rule (blur, ignore_alpha) registered at runtime, Lua `hyprctl eval` first, classic keywords as fallback; a faint rim | `Config.glass` / `glassOpacity`, `Desktops.blurLayer()`, namespace `quickshell:island` |
| `dynamicGlacier` (`handleStyle: strip`) + old `Island.qml` (collapsed handle) | **A visible handle** while auto-hide has hidden the island | `Config.handle` ("strip" / "none") |
| old `Bar.qml` | **A click outside closes** a pinned view (the overlay takes the whole screen while pinned) | `outside` MouseArea, the overlay's mask |
| old `IslandState.qml` + `dynamicGlacier` | **A click on the island itself** pins what it shows: the peek stays, a toast stops timing out; at rest it opens the peek view | `Bar.pinShown()`; Machine: pinning the peeking view adds no history |
| `dynamicGlacier` | **Privacy dots**: orange while the microphone records, green while the camera does (PipeWire links; `fuser /dev/video*` for V4L2) | `services/Privacy.qml`, beside the island |
| `dynamicGlacier` | **Follows the focused monitor** (while idle) | `Triggers.followFocus` |
| `dynamicGlacier` (hover peek) | **A dashboard peek**: time and date, Wi-Fi / Bluetooth / battery at a glance (each opens its view), what's playing with its controls | was `views/Expanded.qml`; hover now peeks into `views/Tabs.qml`, whose status segments each open their view |
| `dynamicGlacier` (collapsed bump) | **Media at rest**: the album cover (or bars) beside the clock; a bolt while charging | `views/Compact.qml` |
| `dynamicGlacier` (`showMedia`) | **A media toast** when a track starts | removed: a track starting no longer opens the media view |
| `dynamicGlacier` (settings panel, `settings.json`) | The look is **editable and remembered** | `views/Theme.qml`, `Config` (QtCore Settings), IPC `style` / `glass` / `handle` |

## Kept as it is here (the new version is better)

- **State**: `Machine.js` (pure, tested) replaces `IslandState.qml`. The old `engaged` flag (keyboard
  activity holds the timeout) became the `key` event, which restarts the countdown instead.
- **Network / Bluetooth data**: `Quickshell.Networking` and `Quickshell.Bluetooth` are D-Bus driven. The old
  services polled `nmcli` every 4 s and `bluetoothctl` every 3 s. Quickshell also merges access points of one
  SSID already, so the old dedupe isn't needed.
- **Bluetooth**: pairing new devices, battery levels, device icons (the old view could only connect paired ones).
- **Power**: the old view ran reboot/shutdown on the first click. Here they ask for a second press.
- **Notifications**: `Notifier.qml` + `views/Notification.qml` are newer than the old `Notify.qml`.

## Not ported

- `dynamicGlacier/BatteryPanel.qml`: charge limit and power profiles. This laptop has no
  `charge_control_end_threshold` and power-profiles-daemon isn't running. Worth adding with the hardware.
- `dynamicGlacier/FrostedGlassSurface.qml`'s Canvas rim (alpha cut-outs, Fresnel gradients): the island
  uses a plain 1 px rim instead; a Canvas repainting every frame of the spring morph costs more.
- `dynamicGlacier`'s exit preview (closing a panel lands on a wide idle first): the spring morph already
  carries the motion.
- `dynamicGlacier`'s favourite apps dock: on the roadmap.
- `views/Dashboard.qml`: a placeholder in the old shell too.
- Real audio bars: the old `CavaBars` was a fake animation as well (cava isn't installed).
