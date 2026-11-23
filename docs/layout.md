# Repo layout

[Docs index](README.md)

This flake follows the **dendritic pattern**. Every file is a small
[flake-parts](https://flake.parts) module that adds named NixOS (and Home Manager) modules, and the host
lists the names it wants. Files never import each other by path.

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
# modules/features/vlc.nix
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
- The first line makes the NixOS module bring its Home Manager part along: importing `vlc` on the
  system side is all it takes. Every feature with a Home Manager part does this, so a feature is always
  one name.

## The host picks the modules

`modules/hosts/omen/default.nix` builds the system from a list of names:

```nix
flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
  modules = with self.modules.nixos; [
    omen
    admin
    base home-manager ssh usb nix-ld session audio networking bluetooth power theme
    hyprland awww quickshell kitty shell yazi fastfetch utils git lazygit neovim vscode
    claude-code python3 webdev firefox libreoffice vlc stremio bittorrent
  ];
};
```

That list is the one place that decides what's on the machine. Remove a name and its feature is gone at
the next rebuild; add one and it's there.

## The folders

| Folder | Holds |
|--------|-------|
| `modules/parts.nix` | flake-parts setup: enables `flake.modules`, sets the system to `x86_64-linux` |
| `modules/hosts/omen/default.nix` | `nixosConfigurations.omen` and the list of modules |
| `modules/hosts/omen/configuration.nix` | the `omen` module: hardware config, lanzaboote, hostname, time zone, keyboard, `stateVersion` |
| `modules/users/admin.nix` | the `admin` module: the account, `home.stateVersion`, git name and email |
| `modules/system/` | system services (audio, network, bluetooth, power, ssh, usb, login session), Nix settings, Home Manager setup, the theme |
| `modules/features/` | apps and tools, one per file |

What each one does: [What's installed](whats-installed.md).

## Adding a feature

1. Create `modules/features/<name>.nix`. For a user-level app (most of them):

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

2. `git add modules/features/<name>.nix`. A flake can't see untracked files.
3. Add the name to the list in `modules/hosts/omen/default.nix`.
4. `rebuild`.

A feature with both parts (like `kitty` or `bittorrent`) puts the `sharedModules` line inside its NixOS
module instead, since one file can only define `flake.modules.nixos.<name>` once.

## Removing a feature

Take its name out of the host's list and rebuild. Keep the file if you might want it back: `steam` and
`luarocks` sit in `features/` unused for exactly this reason.

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

Create `modules/users/<name>.nix` defining `flake.modules.nixos.<name>` with the account and its
`home-manager.users.<name>` settings (copy `admin.nix`), `git add` it, and add the name to the host's
list.

Every feature's Home Manager part goes to **every** Home Manager user (`sharedModules`). For a second
user who should get different apps, that user's own module would import those Home Manager modules
directly instead.

## Adding a host

See [A new machine](new-machine.md).

[← Everyday use](everyday.md) · [Next: What's installed →](whats-installed.md)
