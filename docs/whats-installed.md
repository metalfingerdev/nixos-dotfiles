# What's installed

[Docs index](README.md)

Everything `omen` gets, grouped the way `modules/hosts/omen/default.nix` pulls it in. How the groups fit
together: [Repo layout](layout.md#from-host-to-feature). The template host, `hosts/example`, gets
`desktop`, `terminal`, `development` and `apps` from the same lists, and none of omen's own parts.

## The home host

`modules/hosts/home/` is a second, gaming-only machine, built with `#home`. It gets `admin`, `desktop`, the
`gaming` bundle (Steam), and `kitty`, `shell`, `yazi` and `utils`, but none of the dev tools or apps,
and not `fastfetch`. Its hostname is
`home`, and it leaves out `secure-boot`, so it boots with plain systemd-boot until it has Secure Boot keys.

Its `_hardware.nix` is a placeholder: replace it with `nixos-generate-config --show-hardware-config` run
on that machine before installing (see [A new machine](new-machine.md#adding-a-second-computer)). Its GPU
driver isn't chosen yet either: add `amdgpu` or `nvidia` ([Drivers](#drivers)) to its list once you
know the card.

Everything below is for `omen`.

## omen

`modules/hosts/omen/omen.nix`: its own `_hardware.nix` (next to it), `x86_64-linux`, hostname
`omen`, `stateVersion` 26.05, time zone `Asia/Kolkata`, and blacklists `hp_bioscfg` to silence an HP BIOS
warning. For `admin` on this machine only: the panel's `eDP-1` 1920x1080@144 mode (`~/.config/hypr-host/monitors.lua`), and in `omen/vscode.nix` VS Code's settings linked live to
`config/vscode`, the Claude Code extension, and a wrapper that keeps VS Code on the Radeon so the offloaded
GeForce can power down. Its list also
adds `admin` (below), `claude-code` and the `ai` bundle.
It also sets up hybrid graphics (PRIME offload): the desktop runs on the Radeon iGPU, and the GeForce
stays powered off until you start an app on it with `nvidia-offload <app>`.

## users

`modules/users/`, one person each. A host lists the ones who use it.

| Module | What it sets |
|--------|--------------|
| `admin` | My account (groups `wheel`, `networkmanager`), Home Manager `stateVersion`, git name and email, GitHub over SSH (the `ssh` module and an `insteadOf` rewrite) |
| `changeme` | The template: the same, for whoever copies it; a build warns while it is still `changeme` |

## secure-boot

`modules/system/secure-boot/`: Secure Boot via lanzaboote in place of systemd-boot, keys in
`/var/lib/sbctl`, the 10 newest generations in the boot menu (on omen just the newest plus the running one: its 196 MB EFI partition is shared with Windows 11), and `sbctl` to manage and check the keys
([details](secure-boot.md)).

## Drivers

`modules/drivers/`, one per GPU vendor. omen imports both, for its Radeon iGPU and GeForce GTX 1650.

| Module | What it sets |
|--------|--------------|
| `amdgpu` | Mesa; the kernel's amdgpu driver needs nothing more |
| `nvidia` | NVIDIA's driver in place of nouveau, with its open kernel module (set `hardware.nvidia.open = false` in the host for cards older than Turing) and video memory kept across suspend |

## desktop

`modules/system/desktop/`: `core` plus everything below.

### core

`modules/system/core/`, plus `vim`, `wget` and `git`.

| Module | File | What it sets |
|--------|------|--------------|
| `bootloader` | `core/boot.nix` | systemd-boot with the 10 newest generations in its menu, unless the host adds [`secure-boot`](#secure-boot) |
| `nix` | `core/nix-settings.nix` | Allows unfree packages, turns on flakes and the `nix` command |
| `home-manager` | `system/home-manager/` | Loads Home Manager into NixOS, sharing the system's package set, installing user packages into the user profile, and backing up clashing files as `.backup`. Sets `NIXOS_FLAKE` (where the repo is checked out, default `~/nixos-dotfiles`), which the aliases, agents and island read |
| `etc-nixos` | `core/etc-nixos.nix` | `/etc/nixos` as a read-only copy of the flake the running system was built from |
| `ssh` | `system/ssh/` | Not in core: my `admin` module imports it. Writes `~/.ssh/config` for GitHub (`~/.ssh/id_ed25519_github`) as a real file, not a symlink, so ssh accepts its permissions. The SSH server is `sshd`, which no host uses |
| `nix-ld` | `system/nix-ld/` | Lets downloaded Linux binaries run, with `libstdc++`, OpenSSL, curl and ICU available to them |

### The rest of the desktop

| Module | Folder | What it sets |
|--------|--------|--------------|
| `session` | `system/session/` | The **ly** login screen, GNOME Keyring (unlocked at login), polkit, touchpad support (libinput), printing (CUPS) |
| `hyprland` | `features/hyprland/` | Hyprland with XWayland, started through UWSM, bringing in `awww` and `quickshell`, which its config starts; deploys `~/.config/hypr` from the [hypr repo](dotfiles.md); builds and installs the `hypr-window-rotate` plugin (with a patch so rotated picture-in-picture video isn't cut off) and the `hyprglass` liquid glass plugin, each left out with a warning when nixpkgs' Hyprland isn't the one it was written for |
| `awww` | `features/awww/` | The `awww` wallpaper daemon |
| `quickshell` | `features/quickshell/` | Quickshell (with extra image formats; the island brings its own default wallpaper, lock pictures and look) as a systemd user service that restarts on a crash, the island config from the [quickshell repo](dotfiles.md), `hyprsunset` (night light), `wf-recorder` (screen recording), the clipboard history, the colour picker and `island-calendar` |
| `audio` | `system/audio/` | PipeWire with PulseAudio and ALSA compatibility (incl. 32-bit) and WirePlumber, rtkit; `pavucontrol` and `pulsemixer` |
| `network` | `system/network/` | NetworkManager and the firewall |
| `bluetooth` | `system/bluetooth/` | Bluetooth on at boot, Blueman, fast connect, and a fix that keeps Realtek USB adapters from autosuspending (which made A2DP audio stutter) |
| `power` | `system/power/` | power-profiles-daemon (performance / balanced / power-saver) |
| `usb` | `system/usb/` | udisks2 and gvfs for mounting, `udiskie` automounting USB drives (a user service, no tray icon), `libmtp` for phones |

How the desktop pieces work together: [The desktop](desktop.md).

### theme

`modules/system/theme/`: the *marin* look.

| Module | File | What it sets |
|--------|------|--------------|
| `cursor` | `cursor.nix` | The macOS cursor, 24 px, for GTK, X11 apps and Hyprland (hyprcursor) |
| `gtk` | `gtk.nix` | GTK settings and the Adwaita icon theme |
| `fonts` | `fonts.nix` | JetBrains Mono, Inter and Material Symbols, with fontconfig |

## terminal

`modules/bundles/terminal/`

| Module | What it sets |
|--------|--------------|
| `kitty` | The kitty terminal, with `~/.config/kitty` from the kitty repo |
| `shell` | Bash with aliases: `rebuild`, `boot`, `build`, `try`, `clean` (see [Everyday use](everyday.md)), `btw`. They leave out `#omen`, so they build whichever host they run on. Also direnv with nix-direnv, fzf (Ctrl-R), zoxide (`z`), bat, ripgrep, fd, tree, sqlite, uv and shellcheck; history ignores duplicates and lines starting with a space |
| `yazi` | The yazi file manager, opening text in Neovim, config from the yazi repo |
| `fastfetch` | fastfetch, its config generated by Home Manager and the Marin Kitagawa logo from `assets/fastfetch/logo.gif` |
| `utils` | `brightnessctl`, `playerctl` (media keys), `libnotify` (`notify-send`), `grimblast` (screenshots), `usbutils`, Thunar, `p7zip`, `btop`, `file`, `jq`, `xclip` |

## development

`modules/bundles/development/`

| Module | What it sets |
|--------|--------------|
| `git` | git's shared config and `gh`; git itself comes from `core`. Who you are, and my HTTPS-to-SSH rewrite for GitHub, are in each person's module (`modules/users/`) |
| `lazygit` | lazygit |
| `neovim` | Neovim with `~/.config/nvim` from the nvim repo, plus `ripgrep`, `nil` (Nix language server), `nixpkgs-fmt`, Node and gcc for plugins |
| `vscode` | VS Code (FHS build, so marketplace extensions with binaries work), direnv (also enabled by `shell`), extensions for Nix, Python, Svelte, ESLint, Prettier, Tailwind, Qt/QML and Bun. `nil` and `nixpkgs-fmt` for the Nix extension. Default settings (`features/vscode/_settings.json`: no minimap, formatters for the installed extensions, the Nix language server) are copied in once and are then yours; a host that links its own file is never seeded (omen: [Dotfiles](dotfiles.md#live-linked-vs-code-settings-optional)) |
| `python3` | Python 3 with pandas and numpy |
| `webdev` | Node, pnpm, Bun, TypeScript and its language server, HTML/CSS/JSON/ESLint servers, Svelte language server, Prettier; global installs go to `~/.local/share/pnpm` and `~/.npm-global` (both on `PATH`) |

## apps

`modules/bundles/apps/`

| Module | What it sets |
|--------|--------------|
| `firefox` | Firefox |
| `zen` | Zen, alongside Firefox: vertical tabs, Vim keys (Tridactyl) |
| `libreoffice` | LibreOffice |
| `vlc` | VLC |
| `qimgv` | An image viewer |
| `stremio` | The Stremio streaming server as a user service, started by hand: `systemctl --user start stremio-service` |
| `bittorrent` | qBittorrent, its listening port 51413 opened in the firewall (TCP and UDP), and a first-run config using that port |
| `calibre` | Calibre, for converting e-books and sending them to a Kindle |

## editing

`modules/bundles/editing/`

| Module | What it sets |
|--------|--------------|
| `audacity` | Audacity, for recording and editing audio |
| `kdenlive` | Kdenlive, for editing video |
| `handbrake` | HandBrake, for converting video |
| `gimp` | GIMP |

## omen's own

Personal, so not in any shared bundle; omen lists them itself.

| Module | What it sets |
|--------|--------------|
| `claude-code` | The Claude Code CLI, with the shared deny list (`agent-policy`) merged into its `settings.json`; your other settings stay yours. See [Agents](agents.md) |
| `ai` | The bundle: Ollama (CUDA, localhost), SearXNG, Crush, `nilo-agent` (the island's agent) and `agent-memory` (`~/.local/share/jarvis/memory.md`, seeded once, read by Crush and Claude Code). See [Agents](agents.md) |

## Not used on omen

| Module | Where | What it would add | To turn it on |
|--------|-------|-------------------|---------------|
| `gaming` | `bundles/gaming/` | The `steam` feature: Steam with its 32-bit graphics and runtime. `home` already uses it | Add `gaming` to omen's list |
| `luarocks` | `features/luarocks/` | Lua 5.4 with luarocks, gcc, make and pkg-config, with `~/.luarocks` on the Lua and shell paths | Add it to `development` |
| `sshd` | `system/sshd/` | The OpenSSH server, key-only: no passwords, no root login, only real users, 3 tries, and escalating bans (up to a day) for failed or crashing clients | Add it to the host's list |
| `auto-upgrade` | `system/auto-upgrade/` | Every night at 04:00, build the latest push on GitHub for the machine's hostname and make it the default for the next boot. It only installs what you've pushed, never newer packages | Add it to the host's list |

[← Repo layout](layout.md) · [Next: The desktop →](desktop.md)
