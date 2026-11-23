{ inputs, ... }:
{
  # Secure Boot: lanzaboote signs each generation with the keys in /var/lib/sbctl.
  flake.modules.nixos.bootloader = { lib, pkgs, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    # Makes and enrolls the keys, and checks what lanzaboote signed (sbctl verify).
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
