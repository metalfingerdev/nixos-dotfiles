# Notes for AI agents (Crush, opencode, aider, ...)

This is a NixOS flake for **omen**, an HP Omen laptop (Radeon iGPU + GTX 1650 with 4 GB VRAM, Secure Boot
through lanzaboote, dual-boot with Windows). User: `admin` (`modules/users/admin`). Read `docs/layout.md` before editing.

## Layout (the dendritic pattern)

- `flake.nix` hands `modules/` to import-tree: **every `.nix` file under `modules/` is loaded**, except
  paths with a part starting with `_`. Never import files by path.
- A file publishes named modules: `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>`.
- `modules/features/<n>/` apps and tools, `modules/bundles/<n>/` groups of features, `modules/system/<n>/`
  services, `modules/drivers/<n>/` GPU drivers, `modules/hosts/<host>/` picks names for one machine.
- A feature with a Home Manager part brings it along with
  `flake.modules.nixos.<n>.home-manager.sharedModules = [ self.modules.homeManager.<n> ];`
  (copy `modules/features/vlc/default.nix`).
- `modules/users/<name>/` is one person (account, git identity); `users/changeme` and `hosts/example` are
  the templates for a new person and machine (no `agent` or `ai` bundle, no secure-boot). CI builds `example`.
- Per-person values (account, git identity) live in the user's module, per-machine ones (time zone,
  monitors, omen's VS Code link) in the host, both as plain NixOS and Home Manager options. Never in shared
  modules.
  The checkout path is `home.sessionVariables.NIXOS_FLAKE`. Never hardcode `/home/<user>`.
- A new feature goes in a bundle's `imports`, and a bundle in the host's `modules` list.
- Dotfiles in `config/` are separate repos (hypr, kitty, nvim, quickshell, yazi), pulled in as flake
  inputs. Do not edit them from here.

## How to check your work

```sh
nix flake check                                   # evaluates every output
nixos-rebuild build --flake .#omen                # builds, changes nothing on the running system
```

## Rules

- **Never run `nixos-rebuild switch`, `boot` or `test`, `nix-collect-garbage`, or anything with `sudo`.** The
  person applies changes themselves. Build only.
- Do not touch `modules/system/secure-boot/`, `modules/hosts/*/_hardware.nix`, `boot.*` or the NVIDIA PRIME
  settings unless asked: a mistake there can leave the machine unbootable (the EFI partition is shared
  with Windows and only 196 MB).
- No secrets, keys or tokens in the repo. Everything here is world-readable in the Nix store.
- Prefer small, reviewable diffs, with a comment saying *why* for anything non-obvious.
- Option names change on nixos-unstable. If you are unsure an option exists, check it
  (`nix eval .#nixosConfigurations.omen.options.<path>.type`) instead of guessing.

## Local AI stack (`modules/bundles/agent`)

Ollama (127.0.0.1:11434, CUDA), SearXNG (:8888), Crush. Everything is bound to
localhost. With 4 GB of VRAM, models above ~3B parameters spill into RAM and slow down a lot.

## NixOS rules for agents

- Global installs are read-only (the Nix store). Never `apt`, `pip install` or `sudo`. Need a tool once:
  `nix shell nixpkgs#tool -c tool ...`. Python projects: `uv`.
- Build, never switch: `nixos-rebuild build --flake .#omen` (Crush asks before running it: its block list
  works on the command name). The deny list for agents lives in
  `modules/features/agent-policy/_policy.nix` (Crush and Claude Code read it).
- Shared memory for Crush and Claude Code: `~/.local/share/jarvis/memory.md` (the person's file; never
  overwritten by the flake). The island agent's notes (`~/.config/nihil/nilo.md`) are separate.
- Project skills live in `.claude/skills/` (`add-nix-feature`, `prompt-budget`).
