{ ... }:
{
  flake.modules.homeManager.utils = { pkgs, ... }: {
    home.packages = with pkgs; [
      usbutils
      thunar
      7zip
      file
      jq
    ];
  };
}
