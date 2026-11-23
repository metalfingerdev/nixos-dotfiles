{ ... }:
{
  flake.modules.nixos.omen = {
    imports = [ ./_hardware.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "omen";
    system.stateVersion = "26.05";

    # HP BIOS warning suppress
    boot.blacklistedKernelModules = [ "hp_bioscfg" ];

    # Hybrid graphics: the Radeon runs the desktop, and the GeForce stays powered off until an app is
    # started with `nvidia-offload`. Bus IDs from lspci (01:00.0 and 06:00.0, in decimal).
    hardware.nvidia.prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    hardware.nvidia.powerManagement.finegrained = true;
  };
}
