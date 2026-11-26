# Repo layout

[Docs index](README.md)

This flake follows the **dendritic pattern**, laid out like
[voidarc's config](https://git.voidarc.co.uk/voidarc/nixos). Every file is a small
[flake-parts](https://flake.parts) module that publishes named NixOS (and Home Manager) modules. Small
modules are grouped into bigger ones, and the host imports a handful of names. Files never import each
other by path.

## How a file becomes a module

`flake.nix` hands the whole `modules/` folder to [import-tree](https://github.com/vic/import-tree):

```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```

import-tree loads **every `.nix` file under `modules/`**, in any subfolder, except paths with a part
starting with `_` (e.g. `_notes.nix` or `_old/`). Folders are only for you to find things.

Each file publishes modules under a name:

```nix
# modules/features/vlc/default.nix
{ self, ... }:
{
  flake.modules.nixos.vlc.home-manager.sharedModules = [ self.modules.homeManager.vlc ];

  flake.modules.homeManager.vlc = { pkgs, ... }: {
    home.packages = [ pkgs.vlc ];
  };
}
```

- `flake.modules.nixos.<name>` is a NixOS module.
- `flake.modules.homeManager.<name>` is a Home Manager module.
- The first line makes the NixOS module bring its Home Manager part along, so importing `vlc` on the
  system side is all it takes. Every feature with a Home Manager part does this, so a feature is always
  one name.

## From host to feature

The host imports a dozen names:

```nix
# modules/hosts/omen/default.nix
flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
  modules = with self.modules.nixos; [
    omen                # this machine: hardware, hostname, stateVersion
    admin               # me: account and git identity, from users/
    secure-boot         # lanzaboote instead of plain systemd-boot
    amdgpu              # GPU drivers, from drivers/
    nvidia
    swap                # zram, and a swapfile to hibernate into
    desktop             # everything for a working desktop
    terminal            # from bundles/
    development
    apps
    editing
    agent
    ai
  ];
};
```

Each of those imports more names, down to single features:

```
omen
├── omen                            hosts/omen/omen.nix
├── admin                           users/admin (and ssh: GitHub in ~/.ssh/config)
├── secure-boot                     system/secure-boot
├── amdgpu, nvidia                  drivers/
├── swap                            system/swap
├── desktop                         system/desktop
│   ├── core                        system/core
│   │   ├── bootloader                systemd-boot
│   │   ├── nix                       flakes, unfree packages
│   │   ├── home-manager
│   │   ├── nix-ld
│   │   └── etc-nixos                 /etc/nixos as a copy of the flake
│   ├── session                       ly, keyring, polkit, printing
│   ├── hyprland                      with awww and quickshell
│   ├── wallpapers                    the default pictures
│   ├── audio, network, bluetooth, power, usb
│   └── theme                       system/theme
│       └── cursor, gtk, fonts
├── terminal                        bundles/terminal
│   └── kitty, shell, yazi, fastfetch, utils
├── development                     bundles/development
│   └── git, lazygit, neovim, vscode, python3, webdev
├── apps                            bundles/apps
│   └── firefox, zen, libreoffice, vlc, qimgv, stremio, bittorrent, calibre
├── editing                         bundles/editing
│   └── audacity, kdenlive, handbrake, gimp
├── agent                           bundles/agent
│   └── ollama, searxng, crush, nilo-agent, agent-memory
└── ai                              bundles/ai
    └── claude-code, antigravity
```

The gaming PC's host, `modules/hosts/home/default.nix`, picks from the same names:
`[ home admin desktop gaming kitty shell yazi utils ]`. It leaves out `secure-boot`, so it boots
plain systemd-boot.

A group is just a module that imports others:

```nix
# modules/bundles/development/default.nix
{ self, ... }:
{
  flake.modules.nixos.development.imports = with self.modules.nixos; [
    git
    lazygit
    neovim
    ...
  ];
}
```

## The folders

| Folder | Holds |
|--------|-------|
| `modules/parts.nix` | flake-parts setup: enables `flake.modules`, sets the system to `x86_64-linux` |
| `modules/lib/` | helpers for the other modules, under `self.lib`: `optionalPatch` applies a patch only while it still matches |
| `modules/hosts/<host>/` | `default.nix` (the `nixosConfigurations` entry and its list) and `<host>.nix` (what only that machine has, as the module `<host>`) |
| `modules/users/<name>/` | one person each: the account and git identity (`admin`, and the template `changeme`) |
| `modules/system/core/` | what every machine needs, split into `boot.nix`, `nix-settings.nix`, `etc-nixos.nix`, with `default.nix` grouping them as `core` |
| `modules/system/desktop/` | `desktop`: core plus everything for the graphical session |
| `modules/system/<name>/` | one system service each: audio, network, bluetooth, power, usb, ssh, sshd, secure-boot, session, nix-ld, home-manager, auto-upgrade, swap |
| `modules/system/theme/` | the marin look, split into cursor, gtk and fonts |
| `modules/bundles/<name>/` | bundles of features: terminal, development, apps, editing, gaming, agent, ai |
| `modules/features/<name>/` | one app or tool each, with any small files it needs beside it (e.g. the Hyprland plugin patch) |
| `modules/drivers/<name>/` | GPU drivers, one per vendor: amdgpu, nvidia |

What each one does: [What's installed](whats-installed.md).

## Adding a feature

1. Create `modules/features/<name>/default.nix`. For a user-level app (most of them):

   ```nix
   { self, ... }:
   {
     flake.modules.nixos.obsidian.home-manager.sharedModules = [ self.modules.homeManager.obsidian ];

     flake.modules.homeManager.obsidian = { pkgs, ... }: {
       home.packages = [ pkgs.obsidian ];
     };
   }
   ```

   For something system-wide (a service, a `programs.<x>.enable`), just the NixOS part:

   ```nix
   { ... }:
   {
     flake.modules.nixos.docker = {
       virtualisation.docker.enable = true;
       users.groups.docker.members = [ "admin" ]; # or extraGroups in your user module
     };
   }
   ```

2. `git add` the new folder. A flake can't see untracked files.
3. Add the name to a bundle in `modules/bundles/` (or to `system/desktop` if it's part of the desktop),
   or straight to the host's list.
4. `rebuild`.

A feature with both parts (like `kitty` or `bittorrent`) puts the `sharedModules` line inside its NixOS
module instead, since one file can only define `flake.modules.nixos.<name>` once.

## Adding a bundle

Create `modules/bundles/<name>/default.nix` with an `imports` list, like `development` above. It can also
add packages of its own:

```nix
flake.modules.nixos.music = { pkgs, ... }: {
  imports = with self.modules.nixos; [ spotify ];
  environment.systemPackages = [ pkgs.cava ];
};
```

`git add` it and put its name in the host's list.

## Removing something

Take its name out of whichever list includes it and rebuild. Keep the file if you might want it back:
`luarocks`, `sshd` and `auto-upgrade` (in no list) sit there for exactly this reason, and omen leaves out the `gaming` bundle that
`home` uses.

## Dotfiles in a feature

Features that deploy a config folder read it from a flake input, not from a path in this repo:

```nix
{ inputs, self, ... }:
{
  ...
  flake.modules.homeManager.kitty = {
    home.file.".config/kitty".source = inputs.kitty;
  };
}
```

See [Dotfiles](dotfiles.md) for how those inputs work.

## Adding a user

A person is a module in `modules/users/<name>/`: the account, Home Manager's `stateVersion` and their git
identity. Copy `modules/users/changeme`, set `user` in it, `git add` it, and list the name in each host
they use. The module is named after the account, so `admin`'s is `admin`.

Every feature's Home Manager part goes to **every** Home Manager user (`sharedModules`). For a second
user who should get different apps, that user's module would import those Home Manager modules
directly instead.

## Per-person and per-machine values

There is no custom option layer: a host sets them with NixOS's and Home Manager's own options.

- **The account and git identity**: `users.users.<name>` and `home-manager.users.<name>`
  (`home.stateVersion`, `programs.git.settings.user`). Mine are the `admin` module (`modules/users/admin`),
  imported by omen and home; `modules/users/changeme` is the template a new person copies. No shared
  module needs the user's name:
  features reach every user through `home-manager.sharedModules`.
- **Where this repo is checked out**: `home.sessionVariables.NIXOS_FLAKE`, defaulting to
  `~/nixos-dotfiles` (`system/home-manager`). Nix only sees a store copy of the flake, so this is the one
  value that has to be stated. The rebuild aliases, the agents' rules and the quickshell unit read the
  option at build time.
- **Machine-only settings** go in the host: for everyone on it through `home-manager.sharedModules`
  (monitors, in the example), or for one person through `home-manager.users.<name>`. A host can split
  these into files beside it, as all of them merge into its one module (`omen/vscode.nix`): omen links its VS Code
  settings (`xdg.configFile."Code/User/settings.json"`), adds an extension
  (`programs.vscode.profiles.default.extensions`, lists merge) and writes its monitors
  (`xdg.configFile."hypr-host/monitors.lua"`). `time.timeZone` is set per host.
- **Pictures**: the island ships its defaults (the quickshell repo's `assets/`); people change them in its
  Settings, which fall back to the defaults.

## Using these modules from another flake

Not yet: this repo is clone-only. `flake.modules` is already an output, so
`inputs.<this flake>.modules.nixos.<name>` would work mechanically, but these block a clean export: the Hyprland plugins are pinned to this flake's nixpkgs (a consumer's own nixpkgs
only degrades them with warnings); the modules assume one user; `nix` sets `allowUnfree` and Nix settings
globally; and there's no `templates` output. Until then, copy `modules/hosts/example`.

## Adding a host

See [A new machine](new-machine.md).

[← Everyday use](everyday.md) · [Next: What's installed →](whats-installed.md)
