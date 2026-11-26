{ ... }:
{
  # Plain systemd-boot. Hosts with Secure Boot keys add `secure-boot`, which replaces it with lanzaboote.
  flake.modules.nixos.bootloader = { lib, ... }: {
    boot.loader.systemd-boot = {
      enable = true;
      # Every entry keeps its own kernel and initrd on /boot, which old generations would fill.
      configurationLimit = lib.mkDefault 10; # hosts with a small EFI partition set fewer
    };
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
