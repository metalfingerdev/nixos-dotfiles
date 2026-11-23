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
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   git add hardware-configuration.nix
   ```

4. Secure Boot keys won't exist yet, so follow [Secure Boot: setting it up from scratch](secure-boot.md#setting-it-up-from-scratch):
   build without lanzaboote first.
5. Build:

   ```sh
   sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen \
     --option experimental-features 'nix-command flakes'
   reboot
   ```

   The `--option` is only needed this once; after this build `base` turns flakes on for good.
6. Set your password with `passwd` if the account is new, and get your GitHub SSH key back to
   `~/.ssh/id_ed25519_github` (the `ssh` module points GitHub at it).
7. Clone the dotfile repos into `config/` if you want to edit them
   ([Dotfiles: on a fresh machine](dotfiles.md#on-a-fresh-machine)).

## Adding a second computer

Each machine gets its own host folder and its own name in `flake.nix`'s outputs.

1. On the new machine, generate its hardware config and put it next to the host module, with a name
   starting with `_` so import-tree skips it (it's a NixOS module, not a flake-parts one):

   ```sh
   mkdir -p modules/hosts/laptop2
   nixos-generate-config --show-hardware-config > modules/hosts/laptop2/_hardware.nix
   ```

2. Copy `modules/hosts/omen/` to `modules/hosts/laptop2/` and edit:
   - in `configuration.nix`, rename `flake.modules.nixos.omen` to `laptop2`, import `./_hardware.nix`
     instead of `../../../hardware-configuration.nix`, and set its hostname. Drop the `hp_bioscfg`
     blacklist (it's for HP firmware) and the lanzaboote lines until its keys exist;
   - in `default.nix`, rename `nixosConfigurations.omen` to `laptop2`, use `laptop2` instead of `omen` in
     the list, and keep only the features it should have.
3. `git add modules/hosts/laptop2` and build it with `--flake ~/nixos-dotfiles#laptop2`.

Everything in `system/`, `features/` and `users/` is shared: both hosts pick from the same modules by
name.

You can do the same for omen itself, moving `hardware-configuration.nix` into
`modules/hosts/omen/_hardware.nix`, so each host keeps its own hardware file.

[← Secure Boot](secure-boot.md) · [Next: Troubleshooting →](troubleshooting.md)
