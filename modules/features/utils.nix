{ ... }:
{
  flake.modules.homeManager.utils = { pkgs, ... }: {
    home.packages = with pkgs; [
      usbutils
      thunar
      file
      jq
    ];
  };
}
