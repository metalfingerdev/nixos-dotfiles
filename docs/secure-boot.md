# Secure Boot

[Docs index](README.md)

omen boots with UEFI Secure Boot on, using [lanzaboote](https://github.com/nix-community/lanzaboote)
instead of plain systemd-boot. It's set up in `modules/hosts/omen/configuration.nix`.

## How it works

- Your own signing keys live in `/var/lib/sbctl` (`pkiBundle`) and are enrolled in the firmware, next to
  Microsoft's.
- On every `nixos-rebuild switch` or `boot`, lanzaboote packs each generation's kernel and initrd into a
  single image and signs it with those keys. You don't do anything by hand.
- The firmware only starts images signed by an enrolled key, so a tampered bootloader or kernel won't
  boot.
- systemd-boot's own installer is switched off (`mkForce false`); lanzaboote writes the boot menu
  instead.

## Checking it

```sh
sudo sbctl status     # Setup Mode: disabled, Secure Boot: enabled
sudo sbctl verify     # every file on the EFI partition should say "is signed"
bootctl status        # "Secure Boot: enabled (user)"
```

Run `sudo sbctl verify` after anything that touches booting (a kernel or lanzaboote update). Files
ending in `bzImage.efi` show as unsigned and that's expected. If anything else does, don't reboot:
rebuild again with `boot` and check once more.

## If a boot is refused

A "Secure Boot violation" or a refused image at startup means something wasn't signed:

1. In the boot menu, pick an older generation. They were signed when they were built.
2. Once booted, run `sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen` and `sudo sbctl verify`.
3. If nothing boots, turn Secure Boot off in the firmware settings (F10 on HP at power-on), boot, fix and
   verify, then turn it back on.

Don't delete `/var/lib/sbctl`. Without those keys, new generations can't be signed with the keys the
firmware trusts.

## Setting it up from scratch

For a reinstall or a new machine. Follow the order: enrolling keys before the system is signed would
leave it unbootable.

1. Install and boot NixOS **without** lanzaboote first: comment out the `lanzaboote` import and the
   `boot.lanzaboote` / `systemd-boot` lines in the host's `configuration.nix`, so plain systemd-boot is
   used.
2. Make the keys: `sudo nix run nixpkgs#sbctl -- create-keys` (they go to `/var/lib/sbctl`).
3. Put the lanzaboote lines back, rebuild with `boot`, and run `sudo sbctl verify`. Everything should
   be signed except files ending in `bzImage.efi`, which lanzaboote's guide says are expected to show
   as unsigned.
4. Reboot into the firmware settings, clear the Secure Boot keys / enable **Setup Mode**, then boot back
   in.
5. Enroll: `sudo sbctl enroll-keys --microsoft` (keeps Microsoft's keys so firmware updates and
   option ROMs still load).
6. Reboot, turn Secure Boot on in the firmware, and confirm with `bootctl status`.

The lanzaboote docs have the full details:
<https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md>.

[← Dotfiles](dotfiles.md) · [Next: A new machine →](new-machine.md)
