{ ... }:
{
  flake.modules.homeManager.fastfetch = { pkgs, ... }: {
    home.file.".config/fastfetch".source = ../../config/fastfetch;
    home.packages = [ pkgs.fastfetch ];
  };
}