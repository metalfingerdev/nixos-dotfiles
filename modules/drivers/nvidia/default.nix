{ ... }:
{
  # NVIDIA's own driver in place of nouveau. A laptop with a second GPU also needs PRIME, whose bus
  # IDs belong in that host's module (see omen.nix).
  flake.modules.nixos.nvidia = { lib, ... }: {
    hardware.graphics.enable = true;
    # How NixOS picks the driver, with or without an X server.
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      # The open kernel module, which NVIDIA recommends from Turing (GTX 16xx, RTX 20xx) on. Older
      # cards need false in their host.
      open = lib.mkDefault true;
      # Keeps video memory across suspend, so apps on the GPU survive it.
      powerManagement.enable = true;
    };
  };
}
