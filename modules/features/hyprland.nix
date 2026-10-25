{ ... }:
{
  flake.modules.nixos.hyprland = { ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  # NOTE: hyprland.lua still autostarts awww-daemon and quickshell,
  # so import the `awww` and `quickshell` features alongside this one.
  flake.modules.homeManager.hyprland = { pkgs, ... }: {
    home.file.".config/hypr".source = ../../config/hypr;

    home.packages = with pkgs; [
      grimblast
      libnotify
      brightnessctl
    ];
  };
}