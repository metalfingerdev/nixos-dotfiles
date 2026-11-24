{ self, ... }:
{
  flake.modules.nixos.handbrake.home-manager.sharedModules = [ self.modules.homeManager.handbrake ];

  flake.modules.homeManager.handbrake = { pkgs, ... }: {
    home.packages = [ pkgs.handbrake ];
  };
}
