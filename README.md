# nixos-dotfiles

My NixOS setup for **omen**, an HP Omen laptop: a Hyprland desktop with a Quickshell "island" bar,
the *marin* theme, Secure Boot through lanzaboote, and Home Manager for my user, **admin**.

It is a [flake](https://nixos.wiki/wiki/Flakes) laid out in the
[dendritic pattern](docs/layout.md): every `.nix` file under `modules/` is loaded automatically and
adds one named piece, and the host picks the pieces it wants by name.

## Quick start

```sh
# Apply changes now
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen

# Apply on next boot (safer for kernel, bootloader or desktop changes)
sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen

# Check it builds without touching the running system
nixos-rebuild build --flake ~/nixos-dotfiles#omen
```

The bash aliases `rebuild`, `boot` and `build` run exactly these.

## What's where

```
flake.nix                    inputs (nixpkgs, home-manager, lanzaboote, my dotfile repos) and import-tree
flake.lock                   the exact version of every input
hardware-configuration.nix   generated for omen's disks and hardware
config/                      my dotfiles, each its own git repo (ignored here, pulled in as inputs)
modules/
  parts.nix                  flake-parts setup
  hosts/omen/                the machine: what it imports, its hardware, boot, time zone, keyboard
  users/admin.nix            my account and git identity
  system/                    system services and the theme
  features/                  apps and tools, one file each
docs/                        the guide
```

## Documentation

Start at **[docs/README.md](docs/README.md)**. The most useful pages:

- [NixOS basics](docs/nixos-basics.md): the ideas that make NixOS different, and how to use them
- [Everyday use](docs/everyday.md): rebuild, roll back, update, clean up, try packages
- [Repo layout](docs/layout.md): how the modules fit together, and adding or removing things
- [What's installed](docs/whats-installed.md): every module and what it gives you
- [The desktop](docs/desktop.md): Hyprland, the island, keybinds
- [Dotfiles](docs/dotfiles.md): the five config repos and how to edit them
- [Troubleshooting](docs/troubleshooting.md)
