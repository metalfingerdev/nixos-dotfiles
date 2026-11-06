{ ... }:
{
  flake.modules.homeManager.yazi = { pkgs, ... }: {
    home.file.".config/yazi".source = ../../config/yazi;
    home.packages = [ pkgs.yazi ];
  };
}