# IPC

Target: `island`. View names come from `Registry.qml`. Unknown names are rejected, never replaced with a
default.

| Command | Effect |
|---|---|
| `qs ipc call island open <name>` | pin a view, centred horizontally at the top gap. Opening the open view closes it |
| `qs ipc call island alert <name>` | raise the view as a toast (priority and queue rules apply) |
| `qs ipc call island peek <true\|false>` | show the rest view (Compact) until `peek false`, then hide it (auto-hide) |
| `qs ipc call island togglePeek` | `peek true` if the peek isn't on, else `peek false`: the peek key as one binding |
| `qs ipc call island screen <name>` | show the island on that screen (e.g. `DP-1`); unknown names are ignored |
| `qs ipc call island screens` | list screen names, one per line |
| `qs ipc call island close` | close the current view |
| `qs ipc call island back` | go back one step in history |
| `qs ipc call island autohide <true\|false>` | set auto-hide |
| `qs ipc call island toggleAutohide` | toggle auto-hide |
| `qs ipc call island palette <name>` | a preset palette; `palettes` lists them |
| `qs ipc call island colours <preset\|accent\|wallpaper>` | where colours come from |
| `qs ipc call island accent <#rrggbb>` | a scheme generated from that colour (Material You style) |
| `qs ipc call island variant <tonal\|vibrant\|muted\|mono>` | how colourful a generated scheme is |
| `qs ipc call island mode <dark\|light>` | a generated scheme's dark or light version |
| `qs ipc call island size <80..140>` | the whole island's size, in percent |
| `qs ipc call island style <pill\|notch>` | the island's shape |
| `qs ipc call island glass <true\|false>` | frosted glass; `toggleGlass` flips it |
| `qs ipc call island handle <strip\|none>` | auto-hide: what stays at the top edge while hidden |
| `qs ipc call island debug <true\|false>` | show the debug overlay and the proxy box |
| `qs ipc call island toggleDebug` | toggle debug |
| `qs ipc call island dump` | the full machine snapshot as JSON, with view names instead of numbers |
| `qs ipc call island status` | prints `phase / view / screen`, plus ` / autohide` when it is on |

`open compact` (the rest view) goes home, the same as `close`. `alert compact` is ignored.

Every view opened this way is Pinned, so it has the keyboard (Tab/arrows, Enter, Escape, each
control's shortcut key) until it closes, and each keystroke restarts its timeout. It opens in keyboard
mode: focus rings and shortcut keycaps show until the pointer moves. Names: `tabs` (the hub, also
what hovering shows), `dashboard` (everything), `launcher`, `network`, `bluetooth`, `media`, `mixer`,
`notifications` (`open` = the center, `alert` = the popups), `workspaces` (the overview), `clock`,
`battery`, `power`, `theme` (palette, look, wallpaper; also `settings`), and the toast `switcher`
(`alert switcher` shows the workspace dots).

`peek` is meant for a key's press and release: `peek true` on press, `peek false` on release. When
auto-hide has hidden the island, the press reveals the rest view (Compact) and the release hides it
again at once, with no linger. If the pointer is on the island when you release, it stays until the
pointer leaves (then it lingers `hideMs`, as usual). The rest view never takes the keyboard, so holding
the key doesn't steal typing. Without auto-hide the rest view is always up and the key changes nothing
visible. While a hover peek, a pinned view or a toast is up, `peek` does nothing. Hovering the island
still peeks into `Engine.peekView`; for the hub from the keyboard, use `open tabs`.

`togglePeek` is the same from a single binding on the key's press: the first press is `peek true`,
the next `peek false`. It reads `Engine.peeking`, so it never gets out of step: when something else
clears the peek (a hover peek, a view opening), the next press shows it again.

## Wallpaper

`Wallpaper.qml` has its own target, `wallpaper` (awww; images in `~/Pictures/Wallpapers`):

| Command | Effect |
|---|---|
| `qs ipc call wallpaper next` / `prev` / `random` | change it |
| `qs ipc call wallpaper set <path>` | show that image |
| `qs ipc call wallpaper reload` | re-read the folder |
| `qs ipc call wallpaper current` | print the path showing now |

## Notifications

`Notifier.qml` has its own target, `notifications`, modelled on `dunstctl`:

| Command | Effect |
|---|---|
| `qs ipc call notifications close` | close the top popup (it stays in the center) |
| `qs ipc call notifications closeAll` | close all popups |
| `qs ipc call notifications action` | run the top popup's default action |
| `qs ipc call notifications pop` | pop the newest closed notification up again |
| `qs ipc call notifications clear` | dismiss everything |

## Compositor binding examples

Hyprland:

```ini
bind = SUPER, Space, exec, qs ipc call island open launcher
bind = SUPER, O, exec, qs ipc call island open mixer          # every app's volume
bind = SUPER, G, exec, qs ipc call island open dashboard
bind = SUPER, H, exec, qs ipc call island open tabs
bind  = SUPER, B, exec, qs ipc call island peek true          # hold Super+B to show the clock
bindr = SUPER, B, exec, qs ipc call island peek false
bind = SUPER, Z, exec, qs ipc call island togglePeek          # or: Super+Z shows it, Super+Z again hides it
bind = SUPER, Escape, exec, qs ipc call island close
bind = SUPER, N, exec, qs ipc call island open notifications
```

Note: a view opened over IPC isn't hovered, so its Registry `timeout` starts right away, and each
keystroke starts it over. The timeout is the longest pause allowed between keys, so give views you open
from keybinds one long enough to read and decide (the hub's is 8000 ms).

## Adding a command

Add a typed function to `Ipc.qml` that resolves strings with `Registry.byName` and calls one `Engine`
method. Keep string handling in this file only. A Registry entry's `aliases` are other names
`byName` accepts (`settings` is the theme view).
