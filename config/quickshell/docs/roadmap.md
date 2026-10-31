# Roadmap

## Open

- [ ] Favourite apps dock (dynamicGlacier's "apps" panel): pinned launchers, saved to a state file.
- [ ] Battery: charge limit and power profiles, for hardware that has them (see old-shell-notes.md).
- [ ] Power profiles: the dashboard's segmented row shows once power-profiles-daemon runs
      (`services.power-profiles-daemon.enable`); it is hidden until then.
- [ ] The media view's "Playing next": MPRIS has no queue, so it lists outputs and other players instead.
- [ ] Keyboard, next steps: give each view real keyboard rules as it gets real content.
- [ ] Tests: `modules/tests/machine.test.js` mirrors `Registry.qml` by hand. Keep its `REG` table in sync,
      or generate it.

## Done

- [x] Overview: going to an empty workspace no longer bounces back, and a special workspace can be left
      (click it again, or click a workspace). Both came from acting before the island let go of the
      keyboard: `Engine.closeThen` acts after. Its arrows, digits and wheel now move a selection (Enter goes
      there, Escape stays put) instead of switching while the island holds the keyboard, which bounced
      back the same way on close. The open special workspace is outlined.
- [x] No springs: the morph and the workspace buttons ease on `Motion` (`Config.curve` / `motionMs`), which
      never overshoots, so a notch revealed from auto-hide no longer dips a pixel below the top edge and
      settles back. Hyprland's windows use the same curve (`Glide`), and its spring curves are gone.
- [x] Glass moved to Hyprland: every window at 80 % over a frosted blur, and a `glass` layer rule that
      layers named `glass:*` opt into. The island is `glass:island` and takes the windows' opacity;
      the island's own glass toggle and opacity slider are gone.
- [x] Settings is its own view (size, shape, auto-hide and its handle); Theme is colours and a
      wallpaper grid. Each links to the other.
- [x] Tabs: a workspace button coming or going moves the bar and the island's edges as one motion
      (the buttons move on the island's own motion, toward the width the island is already heading for).
- [x] The glance (Expanded) is gone: hovering the clock peeks into the hub (Tabs). Each segment of
      Tabs' status group opens its own view (network, Bluetooth, notifications, battery). No media toast
      when a track starts. A Mixer view: the output, the microphone and each app's stream, a slider
      each; the media view shows every output's volume, and the wheel over one sets it.
- [x] Keyboard everywhere: spatial arrows, a `shortcut` per control (keycaps while the keyboard is in use),
      Backspace back, bold focus rings that no longer vanish under a still pointer, `KeyHints` footers.
- [x] Theme: colours from a preset, an accent or the wallpaper (generated Material-You-style, with
      tonal/vibrant/muted/mono and dark/light), and a Size for the whole island.
- [x] Colours: a full colour map (hue and lightness) with a saturation slider and a hex field instead of
      twelve swatches; `tint` and, for the wallpaper, saturation and lightness sliders instead of the
      tonal/vibrant/muted/mono styles. A wallpaper colour stays on the wallpaper, for that image.
- [x] Expanded is back, small: the pointer on the island's surface grows the clock into it, after the
      Dynamic Island. No keyboard. Tabs opens with a click; the top edge only reveals the clock.
- [x] Tabs rearranged after Apple's toolbars, with Expanded's clock at the far left and its status group
      at the far right: capsules of one size of button instead of dividers, and a back arrow only
      when there is somewhere to go back to.
- [x] The status group (Tabs, Expanded) has a pill of its own: a segment opens its view, the pill and
      its "tune" button the dashboard.
- [x] Shadows after macOS: floating windows only (hypr/modules/look.lua, rules.lua), deeper in focus; the
      island casts its own (Hyprland has none for layers), deeper once it opens.
- [x] Wide views with big controls; Network and Bluetooth laid out like the dashboard; the dashboard
      without its notification list (a bell with a count opens the center).

- [x] Material 3 redesign (Android's quick settings): Config roles, QuickTile, Slider, Segmented, Chip,
      SearchBar; every view restyled. Focus rings only while the keyboard is in use.
- [x] Compact and Expanded are indicators (clock, media, recording, what's on); Expanded's status group
      opens the dashboard and its search bar the launcher. Tabs is the hub (a click on either opens it).
- [x] Dashboard: Wi-Fi/Bluetooth tiles, quick settings (Do not disturb, night light, caffeine, airplane,
      microphone, dark theme, screen record, screenshot), volume/brightness sliders, power profiles,
      media, notifications.
- [x] Launcher: All / Apps / Files / Actions, usage ranking, file search, island actions, a calculator.
- [x] Workspace switch toast with GNOME-style dots (`Switcher`, `Triggers.switcherToasts`).

- [x] Real Network (Quickshell.Networking) and Bluetooth (Quickshell.Bluetooth) views, plus Media,
      Battery, Clock, Power, Theme (+ wallpaper) and a Workspaces overview with live previews.
- [x] `Config` singleton: palettes, the island's look, fonts; Bar, components and views use it.
- [x] Launcher: ranking (prefix > word > substring > generic name/keywords > in-order letters), icons.
- [x] The best of the old shell's `Bar` and `dynamicGlacier`, merged into the island: pill/notch,
      anti-corners, frosted glass (now Hyprland's), capsule corners, strip handle, outside-click close, click to pin,
      privacy dots, follow the focused monitor, the dashboard peek, media in Compact (see
      [old-shell-notes.md](old-shell-notes.md)).

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
- [x] Velocity-preserving morph (`SpringAnimation` per property). Later replaced by `Motion` (no springs).
- [x] Multi-monitor: one `Bar` per screen, a shared `Engine`, `Engine.activeScreen`, IPC `screen`/`screens`.
- [x] Keyboard: pinned views and the peek view get the keyboard, with default keys from `ViewLoader`
      (Tab/arrows, Enter/Space, Escape). No Registry flag. Hover holds the countdown; each keystroke
      restarts it (`Key` event, `Engine.key()`).
- [x] Cleanup after the hover/keyboard model settled: removed the `center` IPC and the y anchor (the island
      always hangs from the top), `engage`/`release` (nothing held the countdown but hover), `canGoBack`,
      and `Bar.retarget()` (identical to `snap()`).
- [x] Peek key: IPC `peek true`/`peek false` (bind to a key's press/release) is hover from the keyboard.
      `peeking` holds the peek like `hovered`; `enter()` clears it, so it never outlives the peek.
- [x] The peek key shows the rest view (Compact) while held and hides it on release, instead of peeking
      into Expanded. Hover still peeks.
- [x] `debug` lives on `Engine.debug`, toggled over IPC.
- [x] Compact shows a real clock (`SystemClock`). The launcher searches desktop entries.
- [x] `Debug.qml` reads `Engine.snapshot` (it used the removed `IslandState`). Toggled over IPC
      (`debug`, `toggleDebug`). `dump` prints the snapshot as JSON.
- [x] Node test harness for `Machine.js` (`node modules/tests/machine.test.js`).
