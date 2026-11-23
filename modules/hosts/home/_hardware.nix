# Placeholder until this file is replaced with the output of
#   nixos-generate-config --show-hardware-config
# run on the home machine. It only lets the flake evaluate; don't install with it.
{ ... }:
{
  warnings = [ "modules/hosts/home/_hardware.nix is a placeholder: replace it with nixos-generate-config's output before installing" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
}
