{ inputs, ... }:
{
  flake.modules.nixos.omen = { lib, ... }: {
    imports = [
      ../../../hardware-configuration.nix
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "omen";
    time.timeZone = "Asia/Kolkata";
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
    system.stateVersion = "26.05";

    # HP BIOS warning suppress
    boot.blacklistedKernelModules = [ "hp_bioscfg" ];

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
