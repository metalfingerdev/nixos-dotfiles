{ ... }:
{
  # Placeholder: until this is filled in, NVIDIA cards run on nouveau. It will take
  # services.xserver.videoDrivers = [ "nvidia" ] and hardware.nvidia (open = true from Turing on). A
  # laptop with a second GPU also needs PRIME offload, whose bus IDs belong in that host's module.
  flake.modules.nixos.nvidia = { };
}
