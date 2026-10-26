# IPC

Target: `island`. View names come from `Registry.qml`. Unknown names are rejected, never replaced with a
default.

| Command | Effect |
|---|---|
| `qs ipc call island open <name>` | pin a view, centred horizontally at the top gap. Opening the open view closes it |
| `qs ipc call island alert <name>` | raise the view as a toast (priority and queue rules apply) |
| `qs ipc call island peek <true\|false>` | hover from the keyboard: show the peek view (`Engine.peekView`) until `peek false` |
| `qs ipc call island screen <name>` | show the island on that screen (e.g. `DP-1`); unknown names are ignored |
| `qs ipc call island screens` | list screen names, one per line |
| `qs ipc call island close` | close the current view |
| `qs ipc call island back` | go back one step in history |
| `qs ipc call island autohide <true\|false>` | set auto-hide |
| `qs ipc call island toggleAutohide` | toggle auto-hide |
| `qs ipc call island debug <true\|false>` | show the debug overlay and the proxy box |
| `qs ipc call island toggleDebug` | toggle debug |
| `qs ipc call island dump` | the full machine snapshot as JSON, with view names instead of numbers |
| `qs ipc call island status` | prints `phase / view / screen`, plus ` / autohide` when it is on |

`open compact` (the rest view) goes home, the same as `close`. `alert compact` is ignored.

Every view opened this way is Pinned, so it has the keyboard (Tab/arrows, Enter, Escape) until it
closes, and each keystroke restarts its timeout. Notable names: `launcher` (app search) and `notifications`
(`open` = the notification center, `alert` = the popups).

`peek` is meant for a key's press and release: `peek true` on press, `peek false` on release. It does
what hovering does, but at once (no `hoverMs` delay), and it also reveals the island when auto-hide has
hidden it. The peek view has the keyboard while it's up. It stays while the key or the pointer holds it,
and collapses `graceMs` after both let go. Escape, or opening a view from it, ends the peek even while the
key is still held. While a view is pinned or a toast is up, `peek` does nothing. For a single press with
no release bind, use `open expanded` instead (pinned, with a timeout).

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
bind = SUPER, I, exec, qs ipc call island open expanded       # keyboard entry point: Tab to a pill, Enter
bind  = SUPER, B, exec, qs ipc call island peek true          # hold Super+B to peek
bindr = SUPER, B, exec, qs ipc call island peek false
bind = SUPER, Escape, exec, qs ipc call island close
bind = SUPER, N, exec, qs ipc call island open notifications
```

Note: a view opened over IPC isn't hovered, so its Registry `timeout` starts right away, and each
keystroke starts it over. The timeout is the longest pause allowed between keys, so give views you open
from keybinds one long enough to read and decide (the expanded view's is 1500 ms).

## Adding a command

Add a typed function to `Ipc.qml` that resolves strings with `Registry.byName` and calls one `Engine`
method. Keep string handling in this file only.
