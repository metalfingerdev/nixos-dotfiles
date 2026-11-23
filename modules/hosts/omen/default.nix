{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      omen
      auto-upgrade
      desktop
      terminal
      development
      apps
    ];
  };
}
