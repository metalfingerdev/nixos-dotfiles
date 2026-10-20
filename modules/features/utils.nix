{ ... }:
{
  flake.modules.homeManager.utils = { pkgs, ... }: {
    home.packages = with pkgs; [
      usbutils
      thunar
      p7zip
      file
      jq
    ];
  };
}
