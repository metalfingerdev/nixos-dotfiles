{ self, ... }:
{
  flake.modules.nixos.git.home-manager.sharedModules = [ self.modules.homeManager.git ];

  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git.enable = true;
    programs.git.package = null; # core installs git; this only writes the config
    programs.git.settings.url."git@github.com:".insteadOf = "https://github.com/";
    home.packages = [ pkgs.gh ];
  };
}
