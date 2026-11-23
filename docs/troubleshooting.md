# Troubleshooting

[Docs index](README.md)

## A new file or module "doesn't exist"

```
error: attribute 'foo' missing
error: path '/nix/store/…-source/modules/features/foo.nix' does not exist
```

The flake only sees files git tracks. `git add` the new file (it doesn't need to be committed), then
rebuild.

## "warning: Git tree '…/nixos-dotfiles' is dirty"

Just a note that there are uncommitted changes. The build uses them anyway. Commit to make it go away.

## "warning: unknown flake output 'modules'"

Printed by `nix flake check` only. `modules` is the output the dendritic layout publishes; Nix just
doesn't know the name. Harmless.

## My dotfile change didn't show up

`~/.config/<name>` comes from the commit pinned in `flake.lock`, not from `config/<name>`. Commit, push,
`nix flake update <name>`, rebuild, or rebuild once with `--override-input` to use the working copy. See
[Dotfiles](dotfiles.md#editing-a-config). For Hyprland or the island, press Super + R afterwards.

## Home Manager: "Existing file … is in the way" or "would be clobbered"

A real file sits where Home Manager wants to put a link. It normally renames the file to
`<name>.backup` and carries on, but if `<name>.backup` already exists it stops instead. Look at both,
keep what you need, delete the `.backup`, and rebuild.

To see what went wrong: `journalctl -b -u home-manager-admin`.

## The system won't boot, or the desktop is broken after a change

Pick the previous generation in the boot menu. Then fix the repo (`git diff`, `git restore`, or
`git revert`) and rebuild. If you're still logged in, `sudo nixos-rebuild switch --rollback` does the
same thing without a reboot.

## "Secure Boot violation" at startup

See [Secure Boot: if a boot is refused](secure-boot.md#if-a-boot-is-refused).

## An update broke something

```sh
cd ~/nixos-dotfiles
git restore flake.lock      # or git revert the commit that updated it
sudo nixos-rebuild boot --flake .#omen && reboot
```

Then update inputs one at a time (`nix flake update nixpkgs`, …) to find the culprit.

## "repository path … is not owned by current user"

Nix running as root (not through `sudo`, e.g. from a system service) refuses a git repo owned by
`admin`. `sudo nixos-rebuild` is fine. If something needs it, mark the repo safe for root in the system
git config: `programs.git.config.safe.directory = [ "/home/admin/nixos-dotfiles" ];`.

## A downloaded program says "No such file or directory" or a library is missing

Prebuilt Linux binaries expect libraries NixOS doesn't put in `/lib`. `nix-ld` covers the common ones;
add the missing library to `programs.nix-ld.libraries` in `modules/system/nix-ld.nix`, or look for the
program in nixpkgs instead (`nix search nixpkgs <name>`).

## The media keys do nothing

`playerctl` isn't installed. Add `pkgs.playerctl` to `modules/features/utils.nix` and rebuild.

## Running out of disk

Old generations keep their packages. See [Everyday use: cleaning up](everyday.md#cleaning-up).

[← A new machine](new-machine.md) · [Docs index](README.md)
