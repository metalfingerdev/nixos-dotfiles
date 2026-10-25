{ ... }:
{
  flake.modules.homeManager.quickshell = { pkgs, ... }: {
    home.file.".config/quickshell".source = ../../config/quickshell;
    home.packages = [ pkgs.quickshell ];
  };
}