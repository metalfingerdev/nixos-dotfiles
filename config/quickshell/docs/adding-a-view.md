# Adding a view

## 1. Write the QML file

Create `modules/island/views/MyView.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.island
import qs.modules.components

// View contract: set implicitWidth / implicitHeight. The island sizes itself to them.
Item {
    implicitWidth: 360
    implicitHeight: 120

    ColumnLayout {
        anchors.centerIn: parent
        Pill { text: "back"; onClicked: Engine.back() }
    }
}
```

The contract:

- **Size**: set `implicitWidth` and `implicitHeight`. The island morphs to that size. You can bind them to
  content (for example `layout.implicitHeight + 24`), and the island follows when they change.
- **Layout**: the Loader is always the view's final size, so lay out against your own bounds. Don't react to
  the surface's animated size.
- **Clicks**: call `Engine` methods directly. To open a view next to the clicked element, pass the scene x.
  `Pill.clicked(sceneX)` already provides it: `onClicked: x => Engine.open(Engine.View.MyView, x)`.
  Only a mouse click has an x. Pressed from the keyboard, a Pill sends `-1`, so the view opens centred.
- **Style**: Material 3. Take every colour, font and size from `Config` (`import qs.modules.components`):
  the roles `Config.surface`, `container`, `high`, `primary` / `primaryInk` (text on primary),
  `secondary` / `secondaryInk`, `text`, `dim`, `outline`, and `Config.font`, `Config.body`,
  `Config.title`, `Config.radius`, ... so the view follows the palette. Never hard-code a colour.
  `Config.state(base, ink, hovered, pressed)` gives the hover/press state layer. Reuse the components
  (`Header`, `QuickTile`, `Slider`, `Segmented`, `Chip`, `SearchBar`, `ListEntry`, `Pill`, `Toggle`,
  `ScrollList`, `Progress`, `Icon`, ...) and the shared parts (`import qs.modules.parts`:
  `MediaCard`, `NotificationCard`, `StatusGroup`, `WorkspaceDots`, `WallpaperThumb`). No view file
  may share a singleton's name (`Config.qml`, `Wallpaper.qml`, ...): views see their own folder first,
  and it would hide the singleton (hence `views/Wallpapers.qml`). A QML property can't be named `onSomething` (QML reads it as a signal handler and it
  stays black), hence `primaryInk`.
- **Keyboard**: nothing to do for the basics. A pinned view, and the peek view (while hovered), gets the
  keyboard, and `ViewLoader` gives it default keys: Tab moves through focusable items (every control is
  one), arrows move to the nearest one that way, Enter/Space press the focused one, Escape and
  Backspace go back. Give a control a `shortcut: "x"` (Pill, QuickTile, Tile, ListEntry, Chip, a
  Segmented option) and typing x presses it; it shows as a keycap while the keyboard is in use. Keys
  with no control to badge go in a `KeyHints { keys: [["+ −", "volume"]] }` footer. A focusable item of
  your own needs `FocusRing {}` inside it, and an `activate()` if it has a shortcut. For your own rules,
  add `Keys` handlers in the view. Keys you handle are yours, and anything you don't accept still bubbles to the
  defaults. Put `focus: true` on the item that should start focused (otherwise it's the first focusable
  one). Set `activeFocusOnTab: false` on items Tab should skip. See `views/Launcher.qml`: the field keeps
  focus, and Up/Down move a selection instead.
- **Timeout**: hover pauses a pinned view's countdown, and each keystroke restarts it. Keys your view
  accepts don't reach `ViewLoader`, so report them yourself: put
  `Keys.onPressed: event => { Engine.key(); event.accepted = false }` on the item that takes them (the
  launcher's field does).
- **One instance**: the view is loaded on the active screen only, so it exists once even with several
  monitors.

## 2. Add an enum value

In `Engine.qml`, add `MyView` to `enum View`. Add it at the end so existing values keep their numbers.

**Restart the shell after changing the enum** (`qs kill -p .`, then start it again). A hot reload keeps the
old enum, so the new name is `undefined` until a restart. `Registry.get()` rejects non-numbers, so until
then the view is ignored, not stuck. Changes to `parts/` need a restart as well: a hot reload keeps those
types.

## 3. Register it

Add an entry to `Registry.qml`:

```js
{ name: "myview", priority: 2, timeout: 4000, view: Engine.View.MyView,
  url: Qt.resolvedUrl("views/MyView.qml") }
```

| Field      | Effect                                                                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | string used by IPC (`qs ipc call island open myview`)                                                                                                                           |
| `priority` | used by alerts: higher interrupts pinned views and replaces toasts (see [state-machine.md](state-machine.md#alerts-priority-and-the-queue)). An alert may bring its own instead |
| `critical` | optional: the priority to alert with when the event is critical (`Registry.priority(view, true)`)                                                                               |
| `timeout`  | ms before a Pinned/Toast view closes on its own while not held; `0` = never                                                                                                     |
| `queue`    | `true` = a blocked alert of this view waits in the one-slot queue; otherwise it is dropped                                                                                      |
| `opens`    | optional: the view a click on this view's toast opens (default: this view, pinned)                                                                                              |
| `aliases`  | optional: other names IPC accepts                                                                                                                                               |

One view per _thing_, not per variant. Don't add a second view just to change urgency or layout:

- **Urgency**: give the entry a `critical` priority, and have the trigger pass
  `Registry.priority(view, critical)` to `Engine.alert(view, priority)`.
- **Layout**: a view can check the phase. `views/Notification.qml` shows popups as a Toast and the
  notification center when Pinned (`Engine.pinned`). Clicking a toast to pin it then opens its full form.

Unknown views are ignored by the machine (`cfg.known`), so a view without a Registry entry can't be opened.

## 4. Make it reachable

- **From another view**: `Engine.open(Engine.View.MyView, x)`
- **From IPC**: nothing more to do once it is registered
- **As a toast from a system event**: add a `Connections` block in `Triggers.qml` that calls
  `root.alert(Engine.View.MyView)`. Triggers only report events. Priority, timing and queueing come from the
  Registry entry.
- **As the hover peek**: set `Engine.peekView`.

## Toast checklist

For volume, brightness, notifications and similar:

- [ ] Choose `priority` relative to the others: volume/brightness 1, notifications 2 (3 when critical)
- [ ] Choose a short `timeout`: 1500 for sliders. Use `0` when something else decides when it ends (the
      notification popups: `Notifier` times each popup and `Triggers` closes the view when none are left)
- [ ] Set `queue: false` for transient feedback (a stale volume toast is useless) and `queue: true` for
      anything the user must see
- [ ] Guard startup values: `Triggers.alert()` ignores events during the first 2 s
- [ ] Clicking a toast should usually `Engine.open(sameView)` to pin it
