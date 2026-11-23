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

The host imports eight names:

```nix
# modules/hosts/omen/default.nix
flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
  modules = with self.modules.nixos; [
    omen                # this machine: hardware, hostname, stateVersion
    secure-boot         # lanzaboote instead of plain systemd-boot
    amdgpu              # GPU drivers, from drivers/
    nvidia
    desktop             # everything for a working desktop
    terminal            # from bundles/
    development
    apps
  ];
};
```

Each of those imports more names, down to single features:

```
omen
├── omen                            hosts/omen/omen.nix
├── secure-boot                     system/secure-boot
├── amdgpu, nvidia                  drivers/
├── desktop                         system/desktop
│   ├── core                        system/core
│   │   ├── user                      account, git identity
│   │   ├── bootloader                systemd-boot
│   │   ├── nix                       flakes, unfree packages
│   │   ├── locale                    time zone
│   │   ├── home-manager
│   │   ├── ssh                       GitHub in ~/.ssh/config
│   │   └── nix-ld
│   ├── session                       ly, keyring, polkit, printing
│   ├── hyprland                      with awww and quickshell
│   ├── audio, network, bluetooth, power, usb
│   └── theme                       system/theme
│       └── cursor, gtk, fonts
├── terminal                        bundles/terminal
│   └── kitty, shell, yazi, fastfetch, utils
├── development                     bundles/development
│   └── git, lazygit, neovim, vscode, claude-code, python3, webdev
└── apps                            bundles/apps
    └── firefox, libreoffice, vlc, stremio, bittorrent, calibre
```

The gaming PC's host, `modules/hosts/home/default.nix`, picks from the same names:
`[ home desktop gaming kitty shell yazi utils ]`. It leaves out `secure-boot`, so it boots
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
| `modules/hosts/<host>/` | `default.nix` (the `nixosConfigurations` entry and its list) and `<host>.nix` (what only that machine has, as the module `<host>`) |
| `modules/system/core/` | what every machine needs, split into `user.nix`, `boot.nix`, `nix-settings.nix`, `locale.nix`, with `default.nix` grouping them as `core` |
| `modules/system/desktop/` | `desktop`: core plus everything for the graphical session |
| `modules/system/<name>/` | one system service each: audio, network, bluetooth, power, usb, ssh, sshd, secure-boot, session, nix-ld, home-manager, auto-upgrade |
| `modules/system/theme/` | the marin look, split into cursor, gtk and fonts |
| `modules/bundles/<name>/` | bundles of features: terminal, development, apps, gaming |
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
       users.users.admin.extraGroups = [ "docker" ];
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

Users live in `modules/system/core/user.nix` (`user`), which `core` imports. For a second account, add a
file next to it (e.g. `core/guest.nix` defining `flake.modules.nixos.guest`), `git add` it, and add it to
`core`'s list.

Every feature's Home Manager part goes to **every** Home Manager user (`sharedModules`). For a second
user who should get different apps, that user's module would import those Home Manager modules
directly instead.

## Adding a host

See [A new machine](new-machine.md).

[← Everyday use](everyday.md) · [Next: What's installed →](whats-installed.md)
