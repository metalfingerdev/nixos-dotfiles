{ ... }:
{
  # The kernel's amdgpu and Mesa drive AMD GPUs without further setup. Not loaded in the initrd
  # (hardware.amdgpu.initrd.enable): that brings firmware for every AMD GPU and doubles its size,
  # more than omen's 196 MB /boot (shared with Windows) can hold.
  flake.modules.nixos.amdgpu = {
    hardware.graphics.enable = true;
  };
}
