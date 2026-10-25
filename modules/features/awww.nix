{ ... }:
{
  flake.modules.homeManager.awww = { pkgs, ... }: {
    home.packages = [ pkgs.awww ];
  };
}