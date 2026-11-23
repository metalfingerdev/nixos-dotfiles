{ ... }:
{
  # Plain systemd-boot. Hosts with Secure Boot keys add `secure-boot`, which replaces it with lanzaboote.
  flake.modules.nixos.bootloader = {
    boot.loader.systemd-boot = {
      enable = true;
      # Every entry keeps its own kernel and initrd on /boot, which old generations would fill.
      configurationLimit = 10;
    };
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
