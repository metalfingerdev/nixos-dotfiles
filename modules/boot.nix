# Omen-specific boot setup: secure boot (lanzaboote) + HP fixes
{ inputs, lib, ... }:
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # HP bios warning suppress
  boot.blacklistedKernelModules = [ "hp_bioscfg" ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}