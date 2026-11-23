# Everyday use

[Docs index](README.md)

Commands assume the repo is at `~/nixos-dotfiles`. Inside it, `.#omen` works in place of
`~/nixos-dotfiles#omen`.

## Applying changes

| Command | What it does |
|---------|--------------|
| `sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen` | Build, activate now, and make it the boot default (alias `rebuild`) |
| `sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen` | Build and make it the boot default, but keep running the current system until reboot (alias `boot`) |
| `sudo nixos-rebuild test --flake ~/nixos-dotfiles#omen` | Activate now but don't add a boot entry: a reboot brings back the old system |
| `nixos-rebuild build --flake ~/nixos-dotfiles#omen` | Just build, leaving a `./result` link (alias `build`) |

Use `boot` and reboot for changes to the kernel, bootloader, display manager or Hyprland itself.
`switch` is fine for packages, apps and dotfiles.

Always include `#omen`.

## Rolling back

```sh
sudo nixos-rebuild switch --rollback      # back one generation, right now
nixos-rebuild list-generations            # what exists
```

Or pick an older entry in the boot menu at startup. To go back to a specific generation for good, check
out the matching commit of this repo and rebuild.

## Updating

Nothing updates on its own; `flake.lock` holds every input at a fixed commit.

```sh
cd ~/nixos-dotfiles
nix flake update nixpkgs            # newer packages (nixos-unstable)
nix flake update home-manager       # newer Home Manager
nix flake update                    # every input at once, including the dotfile repos
sudo nixos-rebuild boot --flake .#omen && reboot
```

If the result is broken, boot the previous generation, run `git restore flake.lock` (or revert the
commit), and rebuild. Commit `flake.lock` once you're happy, so the repo records what you're running.

To see what you're pinned to: `nix flake metadata ~/nixos-dotfiles`.

## Cleaning up

Old generations keep their packages in the store. To remove them:

```sh
sudo nix-collect-garbage --delete-older-than 14d    # system generations older than 14 days
nix-collect-garbage --delete-older-than 14d         # your own profile's too
sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen   # rewrite the boot menu without them
nix store optimise                                  # hard-link identical files (frees space)
```

`sudo nix-collect-garbage -d` deletes every old generation, leaving only the current one: no rollback
afterwards, so use it only when the current system is known good.

How big is the system? `nix path-info -Sh /run/current-system`.

## Finding and trying packages

```sh
nix search nixpkgs ripgrep           # search (slow the first time)
nix shell nixpkgs#ripgrep nixpkgs#fd # a shell with these, gone when you exit
nix run nixpkgs#cowsay -- hello      # run one without installing
```

To keep a package, add it to a module (see [Repo layout: adding a feature](layout.md#adding-a-feature))
and rebuild.

## Dev shells

For a project, a `flake.nix` with a dev shell:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux; in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [ pkgs.nodejs_22 pkgs.pnpm ];
      };
    };
}
```

Then either `nix develop` to enter it, or `echo "use flake" > .envrc && direnv allow` to have it load
whenever you `cd` in (and in VS Code, through the direnv extension).

## Dotfiles

Your dotfiles are separate repos pulled in as inputs, so editing them has its own loop. See
[Dotfiles](dotfiles.md).

[← NixOS basics](nixos-basics.md) · [Next: Repo layout →](layout.md)
