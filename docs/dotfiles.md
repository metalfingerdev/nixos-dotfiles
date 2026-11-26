# Dotfiles

[Docs index](README.md)

Each config is its own public repo. Hyprland, kitty, Neovim, Quickshell and yazi are pulled in as
flake inputs. VS Code's settings are optionally
[linked live](#live-linked-vs-code-settings-optional).

| Repo | Deployed to | Used by feature |
|------|-------------|-----------------|
| [metalfingerdev/hypr](https://github.com/metalfingerdev/hypr) | `~/.config/hypr` | `hyprland` |
| [metalfingerdev/kitty](https://github.com/metalfingerdev/kitty) | `~/.config/kitty` | `kitty` |
| [metalfingerdev/nvim](https://github.com/metalfingerdev/nvim) | `~/.config/nvim` | `neovim` |
| [metalfingerdev/quickshell](https://github.com/metalfingerdev/quickshell) | `~/.config/quickshell` | `quickshell` |
| [metalfingerdev/yazi](https://github.com/metalfingerdev/yazi) | `~/.config/yazi` | `yazi` |
| [metalfingerdev/vscode](https://github.com/metalfingerdev/vscode) ([optional live link](#live-linked-vs-code-settings-optional)) | `~/.config/Code/User/settings.json` | `vscode` |

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
cd $NIXOS_FLAKE/config/quickshell
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
  --override-input quickshell path:$NIXOS_FLAKE/config/quickshell
```

That uses the files exactly as they are on disk (uncommitted edits too) and doesn't touch `flake.lock`.
Repeat `--override-input` for several repos at once. Once it's right, commit, push and
`nix flake update` as above, or the next normal rebuild goes back to the pinned version.

For Quickshell there's an even faster loop: run your working copy directly with
`qs -p $NIXOS_FLAKE/config/quickshell` (see that repo's README).

## On a fresh machine

The inputs come from GitHub, so a fresh clone of this repo builds without `config/`. To edit them, clone
them back in (vscode too, if you link its settings live):

```sh
cd ~/nixos-dotfiles
for n in hypr kitty nvim quickshell yazi vscode; do git clone git@github.com:metalfingerdev/$n.git config/$n; done
```

## Live-linked VS Code settings (optional)

omen (`modules/hosts/omen/vscode.nix`) sets `xdg.configFile."Code/User/settings.json".source` to `config/vscode/settings.json`, linking VS Code's `settings.json`
straight to a file (`mkOutOfStoreSymlink`) instead of a store copy. Edits, including ones from VS Code's
settings UI, apply with no rebuild, and you commit them in that repo whenever you like. Without it (as in
`hosts/example`), the shared defaults in `modules/features/vscode/_settings.json` are copied in once, and
from then on the file is VS Code's. If the file is missing, the link points at
nothing and VS Code uses defaults. Extensions are installed by Nix (`modules/features/vscode`).

fastfetch isn't a repo: its config is in `modules/features/fastfetch` and its logo in `assets/`. A host
can point the logo elsewhere with `programs.fastfetch.settings.logo.source`.

The island takes one value from here, `NIXOS_FLAKE` (the quickshell repo's README, "From the environment"). hypr reads one machine's screens and keyboard from
`~/.config/hypr-host/` (its `hyprland.lua` explains), which a host writes with `xdg.configFile`.

## Adding another config repo

1. Create the repo on GitHub and push the config to it (its files at the top level).
2. Add an input to `flake.nix`: `foo = { url = "github:metalfingerdev/foo"; flake = false; };`
3. In the feature, take `inputs` in the file's arguments and use
   `home.file.".config/foo".source = inputs.foo;`.
4. `nix flake lock`, then rebuild.
5. Optionally `git clone` it into `config/foo` to edit it there.

[← The desktop](desktop.md) · [Next: Secure Boot →](secure-boot.md)
