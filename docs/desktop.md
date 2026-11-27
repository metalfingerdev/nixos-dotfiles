# The desktop

[Docs index](README.md)

## Logging in

The ly login screen starts on boot. The island also ships a graphical login screen (`config/quickshell/greeter`), off by default: add `island-greeter` to a host's modules list to use it instead of ly (it falls back to a text greeter if Quickshell doesn't start), and remove it to go back. Pick the Hyprland (UWSM) session and log in as `admin`. Your
login also unlocks GNOME Keyring, where apps keep saved passwords.

## What starts with the session

Hyprland's config lives in the [hypr repo](dotfiles.md), deployed to `~/.config/hypr`.
`modules/autostart.lua` starts the apps listed in `session.lua`:

- `awww-daemon`, the wallpaper daemon
- `quickshell`, the island (top bar), notifications and lock screen

Super + R reloads Hyprland's config and restarts both, waiting until the old ones have quit. Use it
after a rebuild that changed the hypr or quickshell config.

`autoload.lua` runs every `.lua` file under `modules/` in path order. A file that errors shows a
notification and is skipped, so one bad module doesn't take the rest down.

## The island

The bar is a "Dynamic Island" built with Quickshell: one rounded surface at the top that morphs
between views. At rest it shows the clock and live indicators; hover to expand it, click for the hub of
tabs, and from there open any view. Backspace or the mouse's back button returns to the previous view;
Escape or a click outside goes home.

Its full docs are in the [quickshell repo](https://github.com/metalfingerdev/quickshell): the README,
`docs/architecture.md`, `docs/ipc.md` (every command it accepts) and `docs/adding-a-view.md`.

## Look

- Wallpaper: through `awww`, picked in the island's theme view (Super + T). The defaults come with the island (its `assets/`);
  Settings → Wallpaper and Settings → Lock screen set your own, and on battery saver the default GIFs
  show their stills
- Cursor: macOS, 24 px, for GTK, X11 apps and Hyprland
- Fonts: JetBrains Mono (terminal), Inter, Material Symbols (island icons)
- Icons: Adwaita
- fastfetch: the Marin Kitagawa logo (Super + Shift + Return opens a terminal running it)

The cursor, fonts and icons come from `modules/system/theme/`. Everything else is set inside the config
repos (colours in `look.lua` (hypr), `kitty.conf`, the island's theme and its pictures), except fastfetch,
whose layout is `modules/features/fastfetch` and logo `assets/fastfetch/logo.gif` here.

## Keybinds

Super is the Windows key.

### Apps

| Keys | Action |
|------|--------|
| Super + Return | Terminal (kitty), floating and centred at 1080x720 |
| Super + Shift + Return | Terminal running fastfetch |
| Super + E | yazi file manager in a terminal |
| Super + D | Launcher |
| Super + W | Firefox |

### Windows

| Keys | Action |
|------|--------|
| Super + Q | Close window |
| Super + Shift + Q | Force-close window |
| Super + F | Fullscreen |
| Super + Shift + Space | Toggle floating |
| Super + Space | Switch focus between tiled and floating windows |
| Super + Ctrl + Space | Pseudo-tile |
| Super + Alt + Space | Toggle split direction |
| Super + A | Pin window and peek the island (two binds share this key) |
| Super + Arrows or H/J/K/L | Move focus |
| Super + Shift + Arrows or H/J/K/L | Move window |
| Super + Alt + Arrows or H/J/K/L | Resize (hold to repeat) |
| Super + Ctrl + Arrows or H/J/K/L | Nudge a floating window (hold to repeat) |
| Super + left drag / right drag | Move / resize with the mouse |
| Super + Shift + Ctrl + Alt + Arrows | Rotate the window to 0°, 90°, 180° or 270° (rotate plugin) |

### Workspaces

| Keys | Action |
|------|--------|
| Super + 1…0 | Go to workspace 1–10 |
| Super + Shift + 1…0 | Move window to workspace 1–10 |
| Super + scroll | Next / previous workspace |
| Super + Escape (Caps Lock on omen, which swaps them) | Show / hide the scratchpad |
| Super + Shift + Escape | Move window to the scratchpad |

### Island

| Keys | Opens |
|------|-------|
| Super + Shift + A | Toggle auto-hide |
| Super + Alt + A | The hub (tabs) |
| Super + Ctrl + A | The expanded view |
| Super + Tab | Workspaces overview |
| Super + G | Dashboard |
| Super + I | Settings |
| Super + Shift + U | Colour picker: a colour from the screen, copied |
| Super + Shift + / | These keybinds, as a list in the island |
| Super + B | Bluetooth |
| Super + Y | Network |
| Super + N | Notifications |
| Super + V | Volume mixer (per app) |
| Super + M | Media |
| Super + U | Battery |
| Super + T | Theme and wallpaper |
| Super + C | Clock |
| Super + X | Power |

### Session

| Keys | Action |
|------|--------|
| Super + Z | Lock the screen |
| Super + R | Reload Hyprland and restart the wallpaper daemon and island |
| Super + Shift + Ctrl + Q | Log out (stops the UWSM session) |

### Screenshots

| Keys | Action |
|------|--------|
| Print | Copy an area |
| Super + Print | Copy the whole screen |
| Super + Shift + Print | Save an area to `~/Pictures/Screenshots/` |

### Hardware keys

Volume up/down/mute and mic mute (through `wpctl`) and brightness up/down (`brightnessctl`) work, even on
the lock screen, and so do next, previous and play/pause (`playerctl`), for any player that supports
MPRIS: most media players and browsers.

All of these are defined in `modules/binds.lua` and `modules/plugins.lua` in the hypr repo.

[← What's installed](whats-installed.md) · [Next: Dotfiles →](dotfiles.md)
