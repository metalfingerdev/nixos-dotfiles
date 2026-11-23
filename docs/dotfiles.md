# Dotfiles

[Docs index](README.md)

The configs for Hyprland, kitty, Neovim, Quickshell, yazi and fastfetch are each their own repo. All but
fastfetch are public on GitHub; fastfetch (with the Marin logo) stays on this machine only.

| Repo | Deployed to | Used by feature |
|------|-------------|-----------------|
| [metalfingerdev/hypr](https://github.com/metalfingerdev/hypr) | `~/.config/hypr` | `hyprland` |
| [metalfingerdev/kitty](https://github.com/metalfingerdev/kitty) | `~/.config/kitty` | `kitty` |
| [metalfingerdev/nvim](https://github.com/metalfingerdev/nvim) | `~/.config/nvim` | `neovim` |
| [metalfingerdev/quickshell](https://github.com/metalfingerdev/quickshell) | `~/.config/quickshell` | `quickshell` |
| [metalfingerdev/yazi](https://github.com/metalfingerdev/yazi) | `~/.config/yazi` | `yazi` |
| `config/fastfetch` (local only) | `~/.config/fastfetch` (`config.jsonc`, `logo.gif`) | `fastfetch` |

## How they get in

Each is a flake input in `flake.nix`:

```nix
quickshell = { url = "github:metalfingerdev/quickshell"; flake = false; };
```

`flake = false` means "just the files". The feature links them into place:

```nix
home.file.".config/quickshell".source = inputs.quickshell;
```

Working copies are checked out in `config/<name>/`, each with its own git history and an `origin` on
GitHub. This repo ignores `config/` (`.gitignore`), so they never show up in its `git status`.

## Editing a config

`flake.lock` pins each repo to one commit, and `~/.config/<name>` is a read-only copy of that commit.
So an edit reaches the system in four steps:

```sh
cd ~/nixos-dotfiles/config/quickshell
# edit...
git commit -am "what changed" && git push

cd ~/nixos-dotfiles
nix flake update quickshell          # move the pin to what you just pushed
rebuild                              # or: sudo nixos-rebuild switch --flake .#omen
```

Then commit `flake.lock` in this repo. For Hyprland or the island, press Super + R after the rebuild.

Name the input in `nix flake update`. Without a name it updates every input, nixpkgs included.

## Trying changes without committing

While you're iterating, point the build at your working copy for one rebuild:

```sh
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen \
  --override-input quickshell path:/home/admin/nixos-dotfiles/config/quickshell
```

That uses the files exactly as they are on disk (uncommitted edits too) and doesn't touch `flake.lock`.
Repeat `--override-input` for several repos at once. Once it's right, commit, push and
`nix flake update` as above, or the next normal rebuild goes back to the pinned version.

For Quickshell there's an even faster loop: run your working copy directly with
`qs -p ~/nixos-dotfiles/config/quickshell` (see that repo's README).

## On a fresh machine

The inputs come from GitHub, so a fresh clone of this repo builds without `config/`. To edit them, clone
them back in:

```sh
cd ~/nixos-dotfiles
for n in hypr kitty nvim quickshell yazi; do git clone git@github.com:metalfingerdev/$n.git config/$n; done
```

## The local-only fastfetch repo

fastfetch's input is `git+file:///home/admin/nixos-dotfiles/config/fastfetch`, so it never leaves this
machine. Two consequences:

- Its loop skips the push: commit in `config/fastfetch`, then `nix flake update fastfetch` and rebuild.
- A fresh clone of this repo can't build until `config/fastfetch` is there. Keep a backup of that folder
  (it's a normal git repo: copy it, or push it to a private remote of your own) and restore it to the
  same path before the first build.

## VS Code settings

`~/.config/Code/User/settings.json` is a link straight to `config/vscode/settings.json`, a local-only
repo, instead of a copy in the Nix store. VS Code reads and writes that file directly, so:

- a change in VS Code's settings UI, or an edit to the file, applies **instantly**, with no rebuild;
- the file stays editable (a store copy is read-only, which is why VS Code couldn't save settings
  before);
- commit in `config/vscode` whenever you want to keep a version.

Extensions are still installed by Nix (`modules/features/vscode`). If `config/vscode/settings.json` is
missing, the link points at nothing and VS Code starts with default settings, so keep `config/vscode` in
your backup with `config/fastfetch`.

## Adding another config repo

1. Create the repo on GitHub and push the config to it (its files at the top level).
2. Add an input to `flake.nix`: `foo = { url = "github:metalfingerdev/foo"; flake = false; };`
3. In the feature, take `inputs` in the file's arguments and use
   `home.file.".config/foo".source = inputs.foo;`.
4. `nix flake lock`, then rebuild.
5. Optionally `git clone` it into `config/foo` to edit it there.

[← The desktop](desktop.md) · [Next: Secure Boot →](secure-boot.md)
