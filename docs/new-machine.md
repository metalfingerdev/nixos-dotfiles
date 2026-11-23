# A new machine

[Docs index](README.md)

## Reinstalling omen

1. Boot the NixOS installer and install as usual (partitions, a user, a network connection). A minimal
   install is enough: this repo brings everything else.
2. After the first boot, get the repo:

   ```sh
   nix-shell -p git --run "git clone https://github.com/metalfingerdev/nixos-dotfiles ~/nixos-dotfiles"
   ```

3. Replace the hardware config, since a fresh install has new disk IDs:

   ```sh
   cd ~/nixos-dotfiles
   nixos-generate-config --show-hardware-config > modules/hosts/omen/_hardware.nix
   git add modules/hosts/omen/_hardware.nix
   ```

4. Secure Boot keys won't exist yet, so follow [Secure Boot: setting it up from scratch](secure-boot.md#setting-it-up-from-scratch):
   build without `secure-boot` first.
5. Build:

   ```sh
   sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen \
     --option experimental-features 'nix-command flakes'
   reboot
   ```

   The `--option` is only needed this once; after this build `core` turns flakes on for good.
6. Set your password with `passwd` if the account is new, and get your GitHub SSH key back to
   `~/.ssh/id_ed25519_github` (the `ssh` module points GitHub at it).
7. Clone the dotfile repos into `config/` if you want to edit them
   ([Dotfiles: on a fresh machine](dotfiles.md#on-a-fresh-machine)).

Clone `config/fastfetch` and `config/vscode` even if you won't edit them. The build works without them,
but fastfetch's logo and VS Code's settings are linked from there
([Dotfiles: live-linked repos](dotfiles.md#live-linked-repos)).

## Adding a second computer

`modules/hosts/home/` is already set up this way for a gaming PC; only its `_hardware.nix` (a
placeholder for now) and its GPU driver (`amdgpu` or `nvidia`, from `modules/drivers/`) are left.

Each machine gets its own host folder and its own name in `flake.nix`'s outputs.

1. On the new machine, generate its hardware config and put it next to the host module, with a name
   starting with `_` so import-tree skips it (it's a NixOS module, not a flake-parts one):

   ```sh
   mkdir -p modules/hosts/laptop2
   nixos-generate-config --show-hardware-config > modules/hosts/laptop2/_hardware.nix
   ```

2. Create `modules/hosts/laptop2/laptop2.nix` defining `flake.modules.nixos.laptop2` (module names
   are shared across the whole flake, so each host's module is named after the host). In it, import
   `./_hardware.nix` and set `nixpkgs.hostPlatform`, `networking.hostName` and `system.stateVersion`
   (copy `modules/hosts/omen/omen.nix`, minus the HP-only `hp_bioscfg` line).
3. Create `modules/hosts/laptop2/default.nix` with `flake.nixosConfigurations.laptop2` importing
   `laptop2` plus whichever of `desktop`, `terminal`, `development`, `apps`, `gaming` it
   should have, and its GPU driver from `modules/drivers/`. Add `secure-boot` only once its keys exist
   ([Secure Boot: setting it up from scratch](secure-boot.md#setting-it-up-from-scratch)).
4. `git add modules/hosts/laptop2` and build it with `--flake ~/nixos-dotfiles#laptop2`.

Everything in `system/`, `bundles/` and `features/` is shared: both hosts pick from the same modules by
name.

Each host keeps its own hardware file in its own folder, so one machine can never pick up another's
disks by accident.

[← Secure Boot](secure-boot.md) · [Next: Troubleshooting →](troubleshooting.md)
