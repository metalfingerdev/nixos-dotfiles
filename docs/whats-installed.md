# What's installed

[Docs index](README.md)

Everything `omen` gets, by module name, as listed in `modules/hosts/omen/default.nix`.

## The machine and the user

| Module | File | What it sets |
|--------|------|--------------|
| `omen` | `hosts/omen/configuration.nix` | `hardware-configuration.nix`, Secure Boot via lanzaboote ([details](secure-boot.md)), hostname `omen`, time zone `Asia/Kolkata`, US keyboard, `stateVersion` 26.05, and blacklists `hp_bioscfg` to silence an HP BIOS warning |
| `admin` | `users/admin.nix` | The `admin` account (groups `wheel`, `networkmanager`), Home Manager `stateVersion`, git name and email |

## System

| Module | What it sets |
|--------|--------------|
| `base` | Allows unfree packages, turns on flakes and the `nix` command, installs `vim` (full) and `wget` |
| `home-manager` | Loads Home Manager into NixOS, sharing the system's package set, installing user packages into the user profile, and backing up clashing files as `.backup` |
| `session` | The **ly** login screen, GNOME Keyring (unlocked at login), polkit, touchpad support (libinput), printing (CUPS), gvfs, X11 support |
| `audio` | PipeWire with PulseAudio and ALSA compatibility (incl. 32-bit) and WirePlumber, rtkit; `pavucontrol` and `pulsemixer` |
| `networking` | NetworkManager and the firewall |
| `bluetooth` | Bluetooth on at boot, Blueman, fast connect, and a fix that keeps Realtek USB adapters from autosuspending (which made A2DP audio stutter) |
| `power` | power-profiles-daemon (performance / balanced / power-saver) |
| `usb` | udisks2 and gvfs for mounting, `udiskie` automounter, `libmtp` for phones, Calibre for e-books |
| `ssh` | OpenSSH server, key-only: no passwords, no root login, only real users, 3 tries, and escalating bans (up to a day) for failed or crashing clients. Also writes `~/.ssh/config` for GitHub (`~/.ssh/id_ed25519_github`) as a real file, not a symlink, so ssh accepts its permissions |
| `nix-ld` | Lets downloaded Linux binaries run, with `libstdc++`, OpenSSL, curl and ICU available to them |
| `theme` | The *marin* look: JetBrains Mono, Inter and Material Symbols fonts, Adwaita icons, the macOS cursor (also as a hyprcursor), GTK, and the Marin Kitagawa fastfetch logo from `~/Pictures/marin-kitagawa.gif` |

## Desktop

| Module | What it sets |
|--------|--------------|
| `hyprland` | Hyprland with XWayland, started through UWSM; hyprlock; deploys `~/.config/hypr` from the [hypr repo](dotfiles.md); builds and installs the `hypr-window-rotate` plugin (with a patch so rotated picture-in-picture video isn't cut off) |
| `awww` | The `awww` wallpaper daemon |
| `quickshell` | Quickshell (with extra image formats), the island config from the [quickshell repo](dotfiles.md), `hyprsunset` (night light) and `wf-recorder` (screen recording) |

How they work together: [The desktop](desktop.md).

## Terminal and tools

| Module | What it sets |
|--------|--------------|
| `kitty` | The kitty terminal, with `~/.config/kitty` from the kitty repo |
| `shell` | Bash with aliases: `rebuild`, `boot`, `build` (see [Everyday use](everyday.md)), `btw`, `daulat` |
| `yazi` | The yazi file manager, opening text in Neovim, config from the yazi repo |
| `fastfetch` | fastfetch with a full module list; the logo comes from `theme` |
| `utils` | `brightnessctl`, `libnotify` (`notify-send`), `grimblast` (screenshots), `usbutils`, Thunar, `p7zip`, `btop`, `file`, `jq` |
| `git` | git system-wide, plus `gh`, and rewrites `https://github.com/` to SSH so pushes use your key |
| `lazygit` | lazygit |
| `neovim` | Neovim with `~/.config/nvim` from the nvim repo, plus `ripgrep`, `nil` (Nix language server), `nixpkgs-fmt`, Node and gcc for plugins |

## Development

| Module | What it sets |
|--------|--------------|
| `vscode` | VS Code (FHS build, so marketplace extensions with binaries work), direnv with nix-direnv, extensions for Nix, Python, Svelte, ESLint, Prettier, Tailwind, Qt/QML, Bun and Claude Code, and your editor settings |
| `claude-code` | The Claude Code CLI |
| `python3` | Python 3 with pandas and numpy |
| `webdev` | Node, pnpm, Bun, TypeScript and its language server, HTML/CSS/JSON/ESLint servers, Svelte language server, Prettier; global installs go to `~/.local/share/pnpm` and `~/.npm-global` (both on `PATH`) |

## Apps

| Module | What it sets |
|--------|--------------|
| `firefox` | Firefox |
| `libreoffice` | LibreOffice |
| `vlc` | VLC |
| `stremio` | The Stremio streaming server as a user service, started with the graphical session |
| `bittorrent` | qBittorrent, its listening port 51413 opened in the firewall (TCP and UDP), and a first-run config using that port |

## Available but not used

These files exist but aren't in the host's list. Add the name to `modules/hosts/omen/default.nix` to turn
one on.

| Module | What it would add |
|--------|-------------------|
| `steam` | Steam (with its 32-bit graphics and runtime) |
| `luarocks` | Lua 5.4 with luarocks, gcc, make and pkg-config, with `~/.luarocks` on the Lua and shell paths |

## Known gaps

- The media keys (next, previous, play/pause) call `playerctl`, which isn't installed, so they do
  nothing. Add `pkgs.playerctl` to `utils` to fix them.

[← Repo layout](layout.md) · [Next: The desktop →](desktop.md)
