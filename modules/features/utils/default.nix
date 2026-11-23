{ self, ... }:
{
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
    ];
  };
}
