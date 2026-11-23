{ ... }:
{
  flake.modules.nixos.omen = {
    imports = [ ./_hardware.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "omen";
    system.stateVersion = "26.05";

    # The EFI partition is 196 MB, shared with Windows 11's boot manager, and every kernel + initrd
    # takes ~45 MB of it. Lanzaboote writes a new one before deleting old ones, so keep the newest and
    # the running one. The running one counts toward the limit: at 1 it would push out every new build.
    boot.lanzaboote.configurationLimit = 2;

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
