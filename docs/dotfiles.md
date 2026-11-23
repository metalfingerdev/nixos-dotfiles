# Dotfiles

[Docs index](README.md)

Each config is its own public repo. Hyprland, kitty, Neovim, Quickshell and yazi are pulled in as
flake inputs; fastfetch and VS Code's settings are [linked live](#live-linked-repos) instead.

| Repo | Deployed to | Used by feature |
|------|-------------|-----------------|
| [metalfingerdev/hypr](https://github.com/metalfingerdev/hypr) | `~/.config/hypr` | `hyprland` |
| [metalfingerdev/kitty](https://github.com/metalfingerdev/kitty) | `~/.config/kitty` | `kitty` |
| [metalfingerdev/nvim](https://github.com/metalfingerdev/nvim) | `~/.config/nvim` | `neovim` |
| [metalfingerdev/quickshell](https://github.com/metalfingerdev/quickshell) | `~/.config/quickshell` | `quickshell` |
| [metalfingerdev/yazi](https://github.com/metalfingerdev/yazi) | `~/.config/yazi` | `yazi` |
| [metalfingerdev/fastfetch](https://github.com/metalfingerdev/fastfetch) ([linked live](#live-linked-repos)) | `~/.config/fastfetch/config.jsonc` and `logo.gif` | `fastfetch` |
| [metalfingerdev/vscode](https://github.com/metalfingerdev/vscode) ([linked live](#live-linked-repos)) | `~/.config/Code/User/settings.json` | `vscode` |

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
them back in (fastfetch and vscode too: their files are linked from there):

```sh
cd ~/nixos-dotfiles
for n in hypr kitty nvim quickshell yazi fastfetch vscode; do git clone git@github.com:metalfingerdev/$n.git config/$n; done
```

## Live-linked repos

`config/fastfetch` (the fastfetch config and the Marin logo) and `config/vscode` (VS Code's
`settings.json`) aren't flake inputs: Home Manager links the files in
`~/.config` straight to them (`mkOutOfStoreSymlink`) instead of to a copy in the Nix store. So:

- an edit applies **instantly**, with no rebuild, commit or `nix flake update`. That includes changes VS
  Code makes from its settings UI, which a read-only store copy used to block;
- commit and push in those repos whenever you want to keep a version;
- the build never reads them, so the flake builds anywhere (even straight from GitHub)
  without them. If one is missing, its links point at nothing: fastfetch falls back to its
  defaults, VS Code to default settings.

Extensions are still installed by Nix (`modules/features/vscode`).

## Adding another config repo

1. Create the repo on GitHub and push the config to it (its files at the top level).
2. Add an input to `flake.nix`: `foo = { url = "github:metalfingerdev/foo"; flake = false; };`
3. In the feature, take `inputs` in the file's arguments and use
   `home.file.".config/foo".source = inputs.foo;`.
4. `nix flake lock`, then rebuild.
5. Optionally `git clone` it into `config/foo` to edit it there.

[← The desktop](desktop.md) · [Next: Secure Boot →](secure-boot.md)
