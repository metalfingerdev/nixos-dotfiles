# Secure Boot

[Docs index](README.md)

omen boots with UEFI Secure Boot on, using [lanzaboote](https://github.com/nix-community/lanzaboote)
instead of plain systemd-boot. It's the `secure-boot` module (`modules/system/secure-boot`), in omen's
host list; a host without it boots plain systemd-boot (`bootloader`, part of `core`).

## How it works

- Your own signing keys live in `/var/lib/sbctl` (`pkiBundle`) and are enrolled in the firmware, next to
  Microsoft's.
- On every `nixos-rebuild switch` or `boot`, lanzaboote packs each generation's kernel and initrd into a
  single image and signs it with those keys. You don't do anything by hand.
- The firmware only starts images signed by an enrolled key, so a tampered bootloader or kernel won't
  boot.
- systemd-boot's own installer is switched off (`mkForce false`); lanzaboote writes the boot menu
  instead.
- The menu keeps the newest generation plus the running one (`configurationLimit = 2`; the running one
  counts toward the limit, so 1 would leave every new build out of the menu): omen's EFI
  partition is only 196 MB, Windows 11's boot manager lives there too, and each kernel and initrd takes
  about 45 MB of it. Lanzaboote only ever deletes its own files (`EFI/nixos`, `EFI/Linux/nixos-*`).
- systemd-boot finds Windows on the same partition and lists it as Windows Boot Manager.

## Checking it

```sh
sudo sbctl status     # Setup Mode: disabled, Secure Boot: enabled
sudo sbctl verify     # every file on the EFI partition should say "is signed"
bootctl status        # "Secure Boot: enabled (user)"
```

Run `sudo sbctl verify` after anything that touches booting (a kernel or lanzaboote update). What must
say "is signed": `EFI/Linux/nixos-generation-*.efi`, `EFI/systemd/systemd-bootx64.efi` and
`EFI/Boot/bootx64.efi`. Expected as unsigned: `EFI/nixos/kernel-*.efi` (the signed generation image
checks it by hash) and everything under `EFI/Microsoft` and `EFI/HP` (signed by their makers, not by
your keys, which is all sbctl checks for). If anything else shows as unsigned, don't reboot: rebuild
again with `boot` and check once more.

## If a boot is refused

A "Secure Boot violation" or a refused image at startup means something wasn't signed:

1. In the boot menu, pick an older generation. They were signed when they were built.
2. Once booted, run `sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen` and `sudo sbctl verify`.
3. If nothing boots, turn Secure Boot off in the firmware settings (F10 on HP at power-on), boot, fix and
   verify, then turn it back on.

Don't delete `/var/lib/sbctl`. Without those keys, new generations can't be signed with the keys the
firmware trusts.

## Small or separate ESP

lanzaboote puts the boot manager, kernels and signed images all on one ESP, the one at
`boot.loader.efi.efiSysMountPoint`. It has no XBOOTLDR support, so the separate `/boot` layout from
[Dual-booting](dual-boot.md#the-efi-partition-and-boot) doesn't work with `secure-boot`. If Windows' ESP is too
small (100 MB), give NixOS its own:

- Make a 1 GB FAT32 partition in the free space and mount it at `/boot`. Leave Windows' ESP alone.
- Raise `boot.lanzaboote.configurationLimit` above the 2 that omen uses. The default is 10.
- systemd-boot only scans its own ESP, so Windows won't appear in its menu. Boot it from the firmware's
  boot menu, or set it as the default there.
- Keep Microsoft's keys when enrolling (`sbctl enroll-keys --microsoft`), or the firmware refuses
  Windows' boot manager.

I haven't tried this layout on real hardware.

## Setting it up from scratch

For a reinstall or a new machine. Follow the order: enrolling keys before the system is signed would
leave it unbootable.

1. Install and boot NixOS without lanzaboote first: leave `secure-boot` out of the host's list
   (`modules/hosts/<host>/default.nix`), so plain systemd-boot is used.
2. Make the keys: `sudo sbctl create-keys` (they go to `/var/lib/sbctl`).
3. Add `secure-boot` to the list, rebuild with `boot`, and run `sudo sbctl verify`. The NixOS files
   should be signed, as in [Checking it](#checking-it).
4. Reboot into the firmware settings, clear the Secure Boot keys / enable Setup Mode, then boot back
   in.
5. Enroll: `sudo sbctl enroll-keys --microsoft` (keeps Microsoft's keys so Windows 11, firmware updates and
   option ROMs still load).
6. Reboot, turn Secure Boot on in the firmware, and confirm with `bootctl status`.

The lanzaboote docs have the full details:
<https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md>.

[← Dotfiles](dotfiles.md) · [Next: A new machine →](new-machine.md)
