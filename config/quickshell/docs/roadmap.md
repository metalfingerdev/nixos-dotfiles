# Roadmap

## Open

- [ ] **Real Network and Bluetooth views.** Both are placeholders ("not connected to a data source yet").
      They need services in `modules/services` (e.g. NetworkManager via `Process`/`nmcli`, and
      `Quickshell.Bluetooth`), then real content in `views/Network.qml` and `views/Bluetooth.qml`.
- [ ] Theme: move colours, radius and font sizes from `Bar.qml`, `Pill.qml` and the views into a `Theme`
      singleton.
- [ ] Launcher: fuzzy matching and ranking. It currently takes the first 5 entries whose name contains the
      query, in `DesktopEntries` order.
- [ ] Keyboard, next steps: give each view real keyboard rules as it gets real content.
- [ ] Tests: `modules/tests/machine.test.js` mirrors `Registry.qml` by hand. Keep its `REG` table in sync,
      or generate it.

## Done

- [x] `Ipc` and `Triggers` are instantiated once in `shell.qml`.
- [x] Services module: `Audio`, `Backlight`, `Notifier`.
- [x] Views for every Registry entry: Volume, Brightness, and Notifications (`Notification.qml`: popups as a
      Toast, the center when Pinned).
- [x] Alert priority travels with the event (`Engine.alert(v, priority)`), so a critical notification is the
      same view alerted more urgently. The three notification views (`notify`, `critical`, center) became one.
- [x] `modules/components/qmldir` declares `module qs.modules.components`.
- [x] Timeouts long enough for IPC (5000/8000). `open compact` goes home instead of pinning forever.
- [x] Countdown no longer restarts on unrelated events: `rearm()` keeps the running timer object.
- [x] `Engine`'s initial snapshot uses `restView`.
- [x] Velocity-preserving morph (`SpringAnimation` per property).
- [x] Multi-monitor: one `Bar` per screen, a shared `Engine`, `Engine.activeScreen`, IPC `screen`/`screens`.
- [x] Keyboard: pinned views and the peek view get the keyboard, with default keys from `ViewLoader`
      (Tab/arrows, Enter/Space, Escape). No Registry flag. Hover holds the countdown; each keystroke
      restarts it (`Key` event, `Engine.key()`).
- [x] Cleanup after the hover/keyboard model settled: removed the `center` IPC and the y anchor (the island
      always hangs from the top), `engage`/`release` (nothing held the countdown but hover), `canGoBack`,
      and `Bar.retarget()` (identical to `snap()`).
- [x] Peek key: IPC `peek true`/`peek false` (bind to a key's press/release) is hover from the keyboard.
      `peeking` holds the peek like `hovered`; `enter()` clears it, so it never outlives the peek.
- [x] `debug` lives on `Engine.debug`, toggled over IPC.
- [x] Compact shows a real clock (`SystemClock`). The launcher searches desktop entries.
- [x] `Debug.qml` reads `Engine.snapshot` (it used the removed `IslandState`). Toggled over IPC
      (`debug`, `toggleDebug`). `dump` prints the snapshot as JSON.
- [x] Node test harness for `Machine.js` (`node modules/tests/machine.test.js`).
