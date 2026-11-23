{ ... }:
{
  flake.modules.nixos.omen = {
    imports = [ ../../../hardware-configuration.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "omen";
    system.stateVersion = "26.05";

    # HP BIOS warning suppress
    boot.blacklistedKernelModules = [ "hp_bioscfg" ];
  };
}
