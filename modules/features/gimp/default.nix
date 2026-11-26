{ self, ... }:
{
  # GIMP, to edit images.
  flake.modules.nixos.gimp.home-manager.sharedModules = [ self.modules.homeManager.gimp ];

  flake.modules.homeManager.gimp = { pkgs, ... }: {
    home.packages = [ pkgs.gimp ];
  };
}
