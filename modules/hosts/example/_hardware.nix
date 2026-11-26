# Placeholder until this file is replaced with the output of
#   nixos-generate-config --show-hardware-config
# run on your machine. It only lets the flake evaluate; don't install with it.
#
# Dual-booting Windows 11? Its EFI partition is usually 100 MB, too small for NixOS kernels (docs/dual-boot.md).
# The usual fix is a second partition mounted at /boot (XBOOTLDR) with the Windows ESP at /efi.
# nixos-generate-config writes both fileSystems entries, but not the boot loader options: also set
# boot.loader.efi.efiSysMountPoint = "/efi" and boot.loader.systemd-boot.xbootldrMountPoint = "/boot"
# in example.nix.
{ ... }:
{
  warnings = [ "modules/hosts/example/_hardware.nix is a placeholder: replace it with nixos-generate-config's output before installing" ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
}
