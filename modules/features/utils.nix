{ ... }:
{
  flake.modules.homeManager.utils = { pkgs, ... }: {
    home.packages = with pkgs; [
      usbutils
      nemo
      file
      jq
    ];
  };
}