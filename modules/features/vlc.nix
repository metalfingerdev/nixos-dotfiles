{ ... }:
{
  flake.modules.homeManager.vlc = { pkgs, ... }: {
    home.packages = [ pkgs.vlc ];
  };
}
