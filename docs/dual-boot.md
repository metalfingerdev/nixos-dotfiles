# Dual-booting with Windows 11

[Docs index](README.md)

Install NixOS beside Windows without losing it. Do the steps in order.

## Before touching disks

1. **Back up** what matters. Resizing a disk is safe, but a typo is not.
2. **Save the BitLocker recovery key** (account.microsoft.com/devices/recoverykey). Changing boot
   settings or partitions can make Windows ask for it at next boot.
3. In Windows, turn off **Fast Startup** (Control Panel → Power Options → Choose what the power buttons
   do) and hibernation (`powercfg /h off` in an admin terminal). Otherwise Windows leaves its disk
   half-mounted and NixOS can't safely touch it.
4. **Shrink the Windows partition from Windows** (Disk Management → right-click C: → Shrink Volume). Leave
   the space unallocated: 60 GB at least, more for a big Nix store. Don't create partitions here.

## The EFI partition and /boot

Windows' EFI System Partition (ESP) is usually **100 MB**, shared by every OS. A NixOS generation puts
~45 MB (kernel + initrd) on it, so it fills after two. Pick one:

- **Big ESP** (omen's is 196 MB): keep everything on it and keep few generations. Set
  `boot.loader.systemd-boot.configurationLimit` (the `example` host sets 3). Check `df -h /boot` after the
  first build.
- **Separate `/boot` (XBOOTLDR), recommended for 100 MB ESPs**: in the installer's partitioner create a
  1 GB FAT32 partition in the free space, mounted at `/boot`, and mount the existing Windows ESP at
  `/efi` (never format it). `nixos-generate-config` only writes the two `fileSystems` entries, so you
  must also tell the boot loader in your host's `<host>.nix`:

  ```nix
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
  ```

  Kernels and initrds then go on the big `/boot` and only the boot manager stays on the ESP. The options'
  own docs recommend exactly these mount points (checked with `nix eval`). I haven't installed this
  layout on real hardware: do the first build with `nixos-rebuild build`, and boot only once it succeeds.

## Installing

1. Turn **Secure Boot off** in the firmware: the NixOS ISO isn't signed for it. Boot the ISO.
2. Install into the free space (manual partitioning: `/` as ext4, the `/boot` above, the Windows ESP at
   `/efi`, no changes to Windows partitions). Remember the **user name** you create.
3. Follow [A new machine](new-machine.md): copy `modules/users/changeme` and `modules/hosts/example`, and set
   `user` to that same name, replace `_hardware.nix` and build.
4. Windows keeps its clock in local time, NixOS in UTC, so each flips the other's. Fix it on the NixOS
   side with `time.hardwareClockInLocalTime = true;` in your host (or set Windows to UTC with a registry
   key).
5. Secure Boot afterwards is optional: [Secure Boot](secure-boot.md) (lanzaboote). Windows 11 works
   without it, but some games' anti-cheat want it, and BitLocker may ask for its key again once you change
   the firmware's keys.

## After Windows updates

A Windows update can put its boot manager first again. NixOS is still installed: choose it from the
firmware's boot menu (often F9/F12/Esc at power-on), then fix the order for good:

```sh
efibootmgr                          # lists entries and the BootOrder
sudo efibootmgr -o 0001,0000        # Boot0001 first (use the numbers listed for yours)
```

## If it doesn't boot

- Boot the NixOS ISO, mount your partitions (`/` on `/mnt`, `/boot` on `/mnt/boot`) and run
  `nixos-enter`, then `nixos-rebuild boot --flake <your checkout>#<host>`.
- Pick an older generation in the boot menu (hold space at power-on if it's hidden).
- Windows asks for the BitLocker key: enter it, then re-check the Secure Boot setting you changed.
- Windows itself is untouched by NixOS, so its own recovery media still works.
