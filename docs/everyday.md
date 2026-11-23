# Everyday use

[Docs index](README.md)

Commands assume the repo is at `~/nixos-dotfiles`. Inside it, `.#omen` works in place of
`~/nixos-dotfiles#omen`.

## Applying changes

| Command | What it does |
|---------|--------------|
| `sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen` | Build, activate now, and make it the boot default (alias `rebuild`) |
| `sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen` | Build and make it the boot default, but keep running the current system until reboot (alias `boot`) |
| `sudo nixos-rebuild test --flake ~/nixos-dotfiles#omen` | Activate now but don't add a boot entry: a reboot brings back the old system (alias `try`) |
| `nixos-rebuild build --flake ~/nixos-dotfiles#omen` | Just build, leaving a `./result` link (alias `build`) |

Use `boot` and reboot for changes to the kernel, bootloader, display manager or Hyprland itself.
`switch` is fine for packages, apps and dotfiles.

Without `#name`, `nixos-rebuild` builds the system named after the hostname (`omen` here, `home` on
the gaming PC). The aliases rely on that, so they work on both machines.

## Rolling back

```sh
sudo nixos-rebuild switch --rollback      # back one generation, right now
nixos-rebuild list-generations            # what exists
```

Or pick an older entry in the boot menu at startup. To go back to a specific generation for good, check
out the matching commit of this repo and rebuild.

## Updating

Nothing updates on its own; `flake.lock` holds every input at a fixed commit. To see what you're pinned
to: `nix flake metadata ~/nixos-dotfiles`.

| Input | What updating it changes |
|-------|--------------------------|
| `nixpkgs` | Every package, the kernel, Hyprland (nixos-unstable) |
| `home-manager` | How your dotfiles and user programs are set up |
| `lanzaboote` | Secure Boot signing |
| `flake-parts`, `import-tree` | How the repo is assembled; nothing on the system by themselves |
| `hypr`, `kitty`, `nvim`, `quickshell`, `yazi` | Your [dotfile repos](dotfiles.md) on GitHub |

`config/fastfetch` and `config/vscode` are linked live, so they never need updating.

### One input at a time

Updating inputs one by one means that if something breaks, you know which one did it.

**0. Start clean.**

```sh
cd ~/nixos-dotfiles
git status        # nothing uncommitted
git pull
```

**1. The loop, for each input:**

```sh
nix flake update nixpkgs                               # one input, by name
build                                                  # build without applying
nix store diff-closures /run/current-system ./result   # what changed
boot && reboot                                         # or `rebuild` for small changes
```

Once it works, `git commit -am "update nixpkgs" && git push`. Push only what works: both machines'
[automatic updates](#automatic-updates) build whatever is pushed. If it's broken, pick the previous
generation in the boot menu, `git restore flake.lock`, and `boot` again.

**2. In this order:**

1. **`nixpkgs`**: the big one; use `boot` and reboot, since it usually brings a new kernel and
   Hyprland. Then:
   - Check Hyprland's version:
     `nix eval .#nixosConfigurations.omen.config.programs.hyprland.package.version`. If it's no longer
     0.56.x, bump the window-rotate plugin in `modules/features/hyprland/default.nix` to the tag that
     matches (its comment says so): change `rev`, set `hash = lib.fakeHash;` (and add `lib` to that
     module's arguments), `build`, and paste the hash the error prints.
   - `sudo sbctl verify`: everything signed except files ending in `bzImage.efi`.
2. **`home-manager`**: `rebuild` is enough.
3. **`lanzaboote`**: `boot`, then **`sudo sbctl verify` before rebooting**.
4. **`flake-parts`**, then **`import-tree`**: just `build`. If `diff-closures` prints nothing, nothing
   changed: commit the lock and move on.
5. **Your dotfile repos**, only after you've pushed changes to them:
   `nix flake update hypr quickshell` (whichever you changed), `rebuild`, then Super + R for Hyprland
   and the island.

**3. Optional:**

- The VS Code marketplace extensions (`qt-core`, `qt-qml`, `bun-vscode`) are pinned by version and hash
  in `modules/features/vscode/default.nix`. Bump them the same way as the plugin, with `lib.fakeHash`.
- Once everything works, `clean` drops generations older than 14 days and rewrites the boot menu.

**4. The gaming PC** updates itself at 04:00 from what you pushed. To do it right away there:
`git pull && rebuild`.

### Everything at once

```sh
nix flake update            # every input
boot && reboot
```

Faster, but if something breaks you won't know which input did it: then restore `flake.lock` and go one
at a time.

## Automatic updates

Both hosts import `auto-upgrade` (`modules/system/auto-upgrade`): every night at 04:00, NixOS fetches
the latest commit **pushed to GitHub**, builds the host matching its hostname, and makes it the default
for the next boot. If the machine was off, it runs at the next startup.

- It builds exactly the pushed `flake.lock`, so it never updates nixpkgs on its own. Package versions
  move when you `nix flake update` and push.
- On omen it builds what's pushed, not what's on disk. A change you've only applied locally (rebuilt
  but not pushed) gets replaced by the pushed version at the next reboot. Push what you want to keep.
- A bad push is installed too, but only at the next boot, and the previous generation stays in the
  boot menu.
- What each run did: `journalctl -u nixos-upgrade`. Run one now: `sudo systemctl start nixos-upgrade`.

## Cleaning up

Old generations keep their packages in the store. The `clean` alias runs the first and third commands
below; to do it by hand:

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
