{ self, ... }:
{
  flake.modules.nixos.awww.home-manager.sharedModules = [ self.modules.homeManager.awww ];

  flake.modules.homeManager.awww = { pkgs, ... }: {
    home.packages = [ pkgs.awww ];
  };
}