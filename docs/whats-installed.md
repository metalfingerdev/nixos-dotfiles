# What's installed

[Docs index](README.md)

Everything `omen` gets, grouped the way `modules/hosts/omen/default.nix` pulls it in. How the groups fit
together: [Repo layout](layout.md#from-host-to-feature).

## omen

`modules/hosts/omen/omen.nix`: `hardware-configuration.nix`, `x86_64-linux`, hostname
`omen`, `stateVersion` 26.05, and blacklists `hp_bioscfg` to silence an HP BIOS warning.

## desktop

`modules/system/desktop/`: `core` plus everything below.

### core

`modules/system/core/`, plus `vim` (full) and `wget`.

| Module | File | What it sets |
|--------|------|--------------|
| `user` | `core/user.nix` | The `admin` account (groups `wheel`, `networkmanager`), Home Manager `stateVersion`, git name and email |
| `bootloader` | `core/boot.nix` | Secure Boot via lanzaboote, keys in `/var/lib/sbctl` ([details](secure-boot.md)) |
| `nix` | `core/nix-settings.nix` | Allows unfree packages, turns on flakes and the `nix` command |
| `locale` | `core/locale.nix` | Time zone `Asia/Kolkata`, US keyboard |
| `home-manager` | `system/home-manager/` | Loads Home Manager into NixOS, sharing the system's package set, installing user packages into the user profile, and backing up clashing files as `.backup` |
| `ssh` | `system/ssh/` | OpenSSH server, key-only: no passwords, no root login, only real users, 3 tries, and escalating bans (up to a day) for failed or crashing clients. Also writes `~/.ssh/config` for GitHub (`~/.ssh/id_ed25519_github`) as a real file, not a symlink, so ssh accepts its permissions |
| `nix-ld` | `system/nix-ld/` | Lets downloaded Linux binaries run, with `libstdc++`, OpenSSL, curl and ICU available to them |

### The rest of the desktop

| Module | Folder | What it sets |
|--------|--------|--------------|
| `session` | `system/session/` | The **ly** login screen, GNOME Keyring (unlocked at login), polkit, touchpad support (libinput), printing (CUPS), gvfs, X11 support |
| `hyprland` | `features/hyprland/` | Hyprland with XWayland, started through UWSM; hyprlock; deploys `~/.config/hypr` from the [hypr repo](dotfiles.md); builds and installs the `hypr-window-rotate` plugin (with a patch so rotated picture-in-picture video isn't cut off) |
| `awww` | `features/awww/` | The `awww` wallpaper daemon |
| `quickshell` | `features/quickshell/` | Quickshell (with extra image formats), the island config from the [quickshell repo](dotfiles.md), `hyprsunset` (night light) and `wf-recorder` (screen recording) |
| `audio` | `system/audio/` | PipeWire with PulseAudio and ALSA compatibility (incl. 32-bit) and WirePlumber, rtkit; `pavucontrol` and `pulsemixer` |
| `network` | `system/network/` | NetworkManager and the firewall |
| `bluetooth` | `system/bluetooth/` | Bluetooth on at boot, Blueman, fast connect, and a fix that keeps Realtek USB adapters from autosuspending (which made A2DP audio stutter) |
| `power` | `system/power/` | power-profiles-daemon (performance / balanced / power-saver) |
| `usb` | `system/usb/` | udisks2 and gvfs for mounting, `udiskie` automounter, `libmtp` for phones, Calibre for e-books |

How the desktop pieces work together: [The desktop](desktop.md).

### theme

`modules/system/theme/`: the *marin* look.

| Module | File | What it sets |
|--------|------|--------------|
| `cursor` | `cursor.nix` | The macOS cursor, 24 px, for GTK, X11 apps and Hyprland (hyprcursor) |
| `gtk` | `gtk.nix` | GTK settings and the Adwaita icon theme |
| `fonts` | `fonts.nix` | JetBrains Mono, Inter and Material Symbols, with fontconfig |
| `marin` | `marin.nix` | The Marin Kitagawa fastfetch logo, from `~/Pictures/marin-kitagawa.gif` |

## terminal

`modules/attrs/terminal/`

| Module | What it sets |
|--------|--------------|
| `kitty` | The kitty terminal, with `~/.config/kitty` from the kitty repo |
| `shell` | Bash with aliases: `rebuild`, `boot`, `build` (see [Everyday use](everyday.md)), `btw`, `daulat` |
| `yazi` | The yazi file manager, opening text in Neovim, config from the yazi repo |
| `fastfetch` | fastfetch with a full module list; the logo comes from `marin` |
| `utils` | `brightnessctl`, `libnotify` (`notify-send`), `grimblast` (screenshots), `usbutils`, Thunar, `p7zip`, `btop`, `file`, `jq` |

## development

`modules/attrs/development/`

| Module | What it sets |
|--------|--------------|
| `git` | git system-wide, plus `gh`, and rewrites `https://github.com/` to SSH so pushes use your key |
| `lazygit` | lazygit |
| `neovim` | Neovim with `~/.config/nvim` from the nvim repo, plus `ripgrep`, `nil` (Nix language server), `nixpkgs-fmt`, Node and gcc for plugins |
| `vscode` | VS Code (FHS build, so marketplace extensions with binaries work), direnv with nix-direnv, extensions for Nix, Python, Svelte, ESLint, Prettier, Tailwind, Qt/QML, Bun and Claude Code, and your editor settings |
| `claude-code` | The Claude Code CLI |
| `python3` | Python 3 with pandas and numpy |
| `webdev` | Node, pnpm, Bun, TypeScript and its language server, HTML/CSS/JSON/ESLint servers, Svelte language server, Prettier; global installs go to `~/.local/share/pnpm` and `~/.npm-global` (both on `PATH`) |

## apps

`modules/attrs/apps/`

| Module | What it sets |
|--------|--------------|
| `firefox` | Firefox |
| `libreoffice` | LibreOffice |
| `vlc` | VLC |
| `stremio` | The Stremio streaming server as a user service, started with the graphical session |
| `bittorrent` | qBittorrent, its listening port 51413 opened in the firewall (TCP and UDP), and a first-run config using that port |

## Available but not used

| Module | Where | What it would add | To turn it on |
|--------|-------|-------------------|---------------|
| `gaming` | `attrs/gaming/` | The `steam` feature: Steam with its 32-bit graphics and runtime | Add `gaming` to the host's list |
| `luarocks` | `features/luarocks/` | Lua 5.4 with luarocks, gcc, make and pkg-config, with `~/.luarocks` on the Lua and shell paths | Add it to `development` |

## Known gaps

- The media keys (next, previous, play/pause) call `playerctl`, which isn't installed, so they do
  nothing. Add `pkgs.playerctl` to `features/utils` to fix them.

[← Repo layout](layout.md) · [Next: The desktop →](desktop.md)
