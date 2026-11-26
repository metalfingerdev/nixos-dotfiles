{ self, ... }:
{
  # git config shared by everyone, and gh. git itself comes from core; who you are (name, email, and
  # my GitHub-over-SSH rewrite) is in your own module in modules/users/.
  flake.modules.nixos.git.home-manager.sharedModules = [ self.modules.homeManager.git ];

  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git.enable = true;
    programs.git.package = null; # core installs git; this only writes the config
    home.packages = [ pkgs.gh ];
  };
}
