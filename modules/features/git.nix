{ ... }:
{
  flake.modules.nixos.git = { ... }: {
    programs.git.enable = true;
  };

  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git.enable = true;
    programs.git.settings.url."git@github.com:".insteadOf = "https://github.com/";
    home.packages = [ pkgs.gh ];
  };
}
