{ inputs, ... }:
{
  # Secure Boot: lanzaboote signs each generation with the keys in /var/lib/sbctl.
  flake.modules.nixos.bootloader = { lib, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
