{ ... }:
{
  # The kernel's amdgpu and Mesa drive AMD GPUs without further setup.
  flake.modules.nixos.amdgpu = {
    hardware.graphics.enable = true;
    # Loads the driver in the initrd, so the console and login screen start at native resolution.
    hardware.amdgpu.initrd.enable = true;
  };
}
