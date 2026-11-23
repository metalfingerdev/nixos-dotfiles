{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      omen
      secure-boot
      amdgpu # Radeon Vega (Cezanne) iGPU
      nvidia # GeForce GTX 1650 Mobile
      swap
      desktop
      terminal
      development
      apps
      editing
      ai
    ];
  };
}
