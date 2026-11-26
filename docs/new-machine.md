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
   `~/.ssh/id_ed25519_github` (the `ssh` module, from `users/admin`, points GitHub at it).
7. Clone the dotfile repos into `config/` if you want to edit them
   ([Dotfiles: on a fresh machine](dotfiles.md#on-a-fresh-machine)).

Only omen live-links `config/vscode`
([Dotfiles](dotfiles.md#live-linked-vs-code-settings-optional)), so clone it only if you link
VS Code's settings the same way.

## A friend's machine (or any new one): start from `example`

`modules/hosts/example/` is a template: a desktop with the terminal, development and apps bundles, and
nothing personal (no `ai`, no `claude-code`, no Secure Boot). Dual-booting Windows? Read
[Dual-booting](dual-boot.md) first.

1. **You**: copy the template user and make it yours. `user` is **the account the installer made**: a
   different name is a new account with no password, and you can't log into it. Uncomment your git
   identity there.

   ```sh
   cp -r modules/users/changeme modules/users/alice      # then set user = "alice" in it
   ```

2. **The machine**: copy the host and rename `example` everywhere in it (the folder, the module name, the
   `nixosConfigurations` name, `networking.hostName`):

   ```sh
   cp -r modules/hosts/example modules/hosts/laptop2
   nixos-generate-config --show-hardware-config > modules/hosts/laptop2/_hardware.nix
   ```

   `_hardware.nix` starts with `_` so import-tree skips it.
3. In `modules/hosts/laptop2/`:
   - `default.nix`: replace `changeme` with your user (`alice`), and uncomment your GPU driver
     (`amdgpu`, `nvidia`).
   - `laptop2.nix`: `time.timeZone`; the Windows clock, monitors and the small-ESP boot options are
     commented examples.
4. `git add modules/users/alice modules/hosts/laptop2` (a flake can't see untracked files). There's no list of hosts to
   edit: import-tree finds the folder.
5. Build, then switch:

   ```sh
   nixos-rebuild build --flake .#laptop2
   sudo nixos-rebuild boot --flake .#laptop2 --option experimental-features 'nix-command flakes'
   ```

6. Nothing touches `~/.ssh` or rewrites git URLs for you: that's in my own module (`users/admin`, the
   `ssh` module and an `insteadOf`). Copy those lines into yours if you want GitHub over SSH.
7. The island brings its own wallpaper and lock screen pictures, so they appear on first login. Add your own
   images to `~/Pictures/Wallpapers`.

Everything in `system/`, `bundles/` and `features/` is shared, so every host picks from the same names.
Each host keeps its own hardware file in its own folder.

The `ai` bundle and `claude-code` are personal and in no shared bundle: add them to the host's list
like omen does.

[← Secure Boot](secure-boot.md) · [Next: Troubleshooting →](troubleshooting.md)
