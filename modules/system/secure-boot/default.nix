{ inputs, ... }:
{
  # Secure Boot: lanzaboote signs each generation with the keys in /var/lib/sbctl (docs/secure-boot.md).
  flake.modules.nixos.secure-boot = { lib, pkgs, ... }: {
    # flake.modules sets no key, so without one a second import would load lanzaboote's module twice.
    key = "modules.nixos.secure-boot";
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    boot.loader.systemd-boot.enable = lib.mkForce false; # lanzaboote writes the boot menu itself
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = lib.mkDefault 10;
    };
    # Makes and enrolls the keys, and checks what lanzaboote signed (sbctl verify).
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
