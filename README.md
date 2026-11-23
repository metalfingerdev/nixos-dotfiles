# nixos-dotfiles

My NixOS setup for **omen**, an HP Omen laptop: a Hyprland desktop with a Quickshell "island" bar,
the *marin* theme, Secure Boot through lanzaboote, and Home Manager for my user, **admin**.

It is a [flake](https://nixos.wiki/wiki/Flakes) built on the
[dendritic pattern](docs/layout.md) and laid out like voidarc's: every `.nix` file under `modules/` is
loaded automatically and adds one named piece, pieces are grouped into bigger ones, and the host picks
a handful of them by name.

## Quick start

```sh
# Apply changes now
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen

# Apply on next boot (safer for kernel, bootloader or desktop changes)
sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen

# Check it builds without touching the running system
nixos-rebuild build --flake ~/nixos-dotfiles#omen
```

The bash aliases `rebuild`, `boot`, `build` and `try` (`nixos-rebuild test`) run these without the
`#omen`: with no name, `nixos-rebuild` picks the system named after the machine's hostname, so the same
aliases work on every host.

## What's where

```
flake.nix                    inputs (nixpkgs, home-manager, lanzaboote, my dotfile repos) and import-tree
flake.lock                   the exact version of every input
config/                      my dotfiles, each its own git repo (ignored here, pulled in as inputs)
modules/
  parts.nix                  flake-parts setup
  hosts/omen/                the laptop: the names it imports, what only it has, its _hardware.nix
  hosts/home/                a gaming-only machine (desktop + Steam); _hardware.nix is a placeholder
  system/core/               what every machine needs: my account, Secure Boot, Nix settings, locale
  system/desktop/            core plus the whole graphical session
  system/<name>/             one system service each (audio, network, bluetooth, ssh, ...)
  system/theme/              the marin look: cursor, GTK, fonts
  bundles/<name>/            bundles of features: terminal, development, apps, gaming
  features/<name>/           apps and tools, one folder each
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
