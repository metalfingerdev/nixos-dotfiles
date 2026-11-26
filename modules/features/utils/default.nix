{ self, ... }:
{
  # Small tools the desktop calls (brightnessctl and playerctl for hypr's brightness and media keys,
  # grimblast for screenshots, libnotify's notify-send) and everyday command-line ones.
  flake.modules.nixos.utils.home-manager.sharedModules = [ self.modules.homeManager.utils ];

  flake.modules.homeManager.utils = { pkgs, ... }: {
    home.packages = with pkgs; [
      brightnessctl
      playerctl
      libnotify
      grimblast
      usbutils
      thunar
      p7zip
      xclip
      btop
      file
      jq
      gifsicle
    ];
  };
}
