{ ... }:
{
  flake.modules.homeManager.utils = { pkgs, ... }: {
    home.packages = with pkgs; [
      brightnessctl
      libnotify
      grimblast
      usbutils
      thunar
      p7zip
      file
      jq
    ];
  };
}
