{ ... }:
{
  # The kernel's amdgpu and Mesa drive AMD GPUs without further setup. Not loaded in the initrd
  # (hardware.amdgpu.initrd.enable): that brings firmware for every AMD GPU and doubles its size,
  # more than a small EFI partition shared with Windows can hold (omen's is 196 MB, Windows'
  # default 100 MB).
  flake.modules.nixos.amdgpu = {
    hardware.graphics.enable = true;
  };
}
