---
name: add-nix-feature
description: Add a feature module to this flake the dendritic way (folder, published names, bundle, host, checks, never switch).
---

1. Create `modules/features/<n>/default.nix`, copying `modules/features/vlc/default.nix`: publish
   `flake.modules.nixos.<n>` and, for a Home Manager part, `flake.modules.homeManager.<n>` brought along with
   `flake.modules.nixos.<n>.home-manager.sharedModules = [ self.modules.homeManager.<n> ];`.
2. Files that are not modules (data, scripts, templates) start with `_`, so import-tree skips them. Never import a module by path.
3. Add `<n>` to a bundle's `imports` in `modules/bundles/<b>/default.nix`; a new bundle goes in the host's `modules` list (`modules/hosts/omen/default.nix`).
4. Check every option you use: `nix eval .#nixosConfigurations.omen.options.<path>.type` (Home Manager: under `options.home-manager.users.type.getSubOptions`). Don't guess.
5. `git add` new files (flakes only see tracked files), then `nix flake check` and `nixos-rebuild build --flake .#omen`.
6. Never run `nixos-rebuild switch|boot|test`, `nix-collect-garbage` or anything with sudo; the person applies changes. No secrets (the store is world-readable).
7. Don't touch `modules/system/secure-boot/`, `_hardware.nix`, `boot.*` or PRIME. Add a "why" comment for anything non-obvious.
