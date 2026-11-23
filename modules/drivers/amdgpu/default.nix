{ ... }:
{
  # Placeholder. The kernel's amdgpu and Mesa (hardware.graphics, on through Hyprland) already drive
  # AMD GPUs; settings beyond that go here.
  flake.modules.nixos.amdgpu = { };
}
