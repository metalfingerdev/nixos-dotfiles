{ inputs, self, ... }:
{
  # A gaming-only machine: the desktop and Steam, no dev tools or apps.
  flake.nixosConfigurations.home = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      home
      auto-upgrade
      desktop
      gaming
      kitty
      shell
      yazi
      utils
    ];
  };
}
