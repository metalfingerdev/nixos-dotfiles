# nixos-dotfiles

My NixOS config for a laptop that dual-boots Windows 11. It has a Hyprland desktop with a Quickshell
bar (the island), Secure Boot through lanzaboote, and Home Manager for my user, admin.

To install it on your own machine, copy one user module and one host folder. See
[A new machine](docs/new-machine.md) and [Dual-booting](docs/dual-boot.md).

It's a [flake](https://nixos.wiki/wiki/Flakes) built on the [dendritic pattern](docs/layout.md). Every
`.nix` file under `modules/` is loaded automatically and adds one named module. Modules are grouped into
bundles, and each host picks the ones it wants by name.

## Rebuilding

```sh
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen   # apply now
sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen     # apply on next boot
nixos-rebuild build --flake ~/nixos-dotfiles#omen         # build only, change nothing
```

The bash aliases `rebuild`, `boot`, `build` and `try` (`nixos-rebuild test`) run the same commands without
the `#omen`. Without a name, `nixos-rebuild` uses the host named after the machine's hostname, so the
aliases work on every host.

## Layout

```
flake.nix                inputs and import-tree
flake.lock               pinned input versions
assets/                  fastfetch logo
config/                  dotfiles, each its own git repo (ignored here, used as flake inputs)
modules/
  parts.nix              flake-parts setup
  hosts/omen/            my laptop
  hosts/home/            gaming-only machine (_hardware.nix is a placeholder)
  hosts/example/         template for a new machine (CI builds it)
  users/admin/           my account and git identity
  users/changeme/        template for a new user
  system/core/           bootloader, Nix settings, Home Manager
  system/desktop/        core plus the graphical session
  system/<name>/         one service each: audio, network, bluetooth, secure-boot, ...
  system/theme/          cursor, GTK, fonts
  bundles/<name>/        groups of features: terminal, development, apps, editing, gaming
  features/<name>/       one app or tool per folder
  drivers/<name>/        GPU drivers, one per vendor
docs/                    documentation
.github/workflows/       CI: evaluates everything and builds hosts/example
```

## Docs

The index is [docs/README.md](docs/README.md). Main pages:

- [NixOS basics](docs/nixos-basics.md)
- [Everyday use](docs/everyday.md): rebuild, roll back, update, clean up
- [Repo layout](docs/layout.md): how modules fit together, adding and removing things
- [What's installed](docs/whats-installed.md)
- [The desktop](docs/desktop.md): Hyprland, the island, keybinds
- [Dotfiles](docs/dotfiles.md): the config repos and how to edit them
- [A new machine](docs/new-machine.md) and [Dual-booting](docs/dual-boot.md)
- [Troubleshooting](docs/troubleshooting.md)
