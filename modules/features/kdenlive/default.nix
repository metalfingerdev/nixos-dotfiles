{ self, ... }:
{
  # Kdenlive, to edit video.
  flake.modules.nixos.kdenlive.home-manager.sharedModules = [ self.modules.homeManager.kdenlive ];

  flake.modules.homeManager.kdenlive = { pkgs, ... }: {
    home.packages = [ pkgs.kdePackages.kdenlive ];
  };
}
