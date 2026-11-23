{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      omen
      desktop
      terminal
      development
      apps
    ];
  };
}
