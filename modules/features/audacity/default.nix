{ self, ... }:
{
  # Audacity, to record and edit audio.
  flake.modules.nixos.audacity.home-manager.sharedModules = [ self.modules.homeManager.audacity ];

  flake.modules.homeManager.audacity = { pkgs, ... }: {
    home.packages = [ pkgs.audacity ];
  };
}
