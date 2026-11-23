# NixOS basics

[Docs index](README.md)

NixOS feels different from other Linux distributions because of a handful of ideas. Once they click,
they're the reason to use it.

## The system is a build output

On most distros you change the system by running commands (`apt install`, editing `/etc`, enabling
services) and the result is whatever state those commands left behind. On NixOS you **describe** the
system in `.nix` files, and `nixos-rebuild` builds it from that description and switches to it.

- Packages, services, users, `/etc` files, the bootloader and the kernel all come from this repo.
- `/etc` is mostly generated: a hand edit there is overwritten by the next rebuild. Change the module
  instead.
- If it isn't in the config, it isn't on the system after a rebuild. That's what keeps the system from
  drifting.

**Habit:** when you want something, find the option for it (see [Finding options](#finding-options)),
put it in a module, rebuild.

## The Nix store

Everything Nix builds lives in `/nix/store`, in a folder named by a hash of everything that went into
it, like `/nix/store/b6gvzjyb2pg0…-firefox-140.0`. Two versions of the same thing never collide, nothing
is overwritten in place, and a build is the same wherever it runs.

The store only grows until you clean it ([Everyday use: cleaning up](everyday.md#cleaning-up)).

## Generations and rollback

Every `nixos-rebuild switch` or `boot` makes a new **generation**: a complete, bootable system. The old
ones stay until you delete them.

- Each generation appears in the boot menu. If a change breaks boot, pick the previous one.
- `sudo nixos-rebuild switch --rollback` goes back one generation without rebooting.
- This makes experimenting cheap: try it, and if it's wrong, roll back.

Home Manager has its own generations for your dotfiles, but here it runs as part of the system, so
rolling back the system rolls back your dotfiles too.

## Flakes and the lock file

This repo is a **flake**: `flake.nix` lists its inputs (nixpkgs, Home Manager, lanzaboote and my
dotfile repos) and `flake.lock` pins each one to an exact commit.

- Every build uses exactly the locked versions, so the system only changes when you change the repo.
- Nothing updates until you run `nix flake update` ([Everyday use: updating](everyday.md#updating)).
- `flake.lock` is committed, so any commit of this repo rebuilds the same system it built then.
- A flake only sees files git knows about. **`git add` a new file before rebuilding**, or Nix acts
  as if it doesn't exist.

## Home Manager

[Home Manager](https://github.com/nix-community/home-manager) does for your home folder what NixOS does
for the system: user packages, dotfiles in `~/.config`, user services. It's loaded as a NixOS module
here, so one `nixos-rebuild` applies both.

- Files it manages are symlinks into the store and read-only. Edit the source (in this repo, or in
  one of the [dotfile repos](dotfiles.md)), then rebuild.
- If a real file is already where it wants to link, it renames that file to `<name>.backup` first.

## Unfree software

`nixpkgs.config.allowUnfree = true` is set in `system/core/nix-settings.nix`, so VS Code, Steam, Stremio and other
non-free packages build.

## Getting the most out of it

**Try before you install.** `nix shell nixpkgs#cowsay` gives you a shell with a package in it, and when
you exit it's gone. `nix run nixpkgs#hello` runs one directly. Only add it to a module once you know you
want to keep it.

**Never `nix-env -i`.** It installs outside the config, so the package is invisible to this repo and
lingers across rebuilds. Use a module, or `nix shell` for one-offs.

**Per-project dev environments.** Put a `flake.nix` with a `devShells.default` in a project, add a
`.envrc` containing `use flake`, and run `direnv allow` once. From then on, entering the folder loads
that project's exact tools (`direnv` and `nix-direnv` are installed with the VS Code module), and VS Code
picks them up through the direnv extension. Different projects can need different Node or Python
versions without clashing.

**Prebuilt binaries.** Programs downloaded as plain Linux binaries normally fail on NixOS, because
there is no `/lib` with the usual libraries. `nix-ld` (`system/nix-ld/`) provides a loader for them;
if one complains about a missing library, add that library to `programs.nix-ld.libraries` there.

**See what a change does before applying it.** Build without switching, then compare:

```sh
nixos-rebuild build --flake ~/nixos-dotfiles#omen
nix store diff-closures /run/current-system ./result
```

**Ask the config questions.** You can query any option's final value:

```sh
nix eval ~/nixos-dotfiles#nixosConfigurations.omen.config.networking.hostName
nix repl
# then:  :lf ~/nixos-dotfiles
#        nixosConfigurations.omen.config.hardware.bluetooth.settings
```

**Keep the repo committed.** Commit before risky changes. If an update or edit goes wrong, roll back the
generation, then `git restore` or `git revert` the repo, and the two match again.

## Finding options

- NixOS options and packages: <https://search.nixos.org>
- Home Manager options: <https://home-manager-options.extranix.com>
- Hyprland: <https://wiki.hypr.land>
- The NixOS manual: <https://nixos.org/manual/nixos/unstable/>

This system follows `nixos-unstable`, so search the **unstable** channel on search.nixos.org.

[Next: Everyday use →](everyday.md)
