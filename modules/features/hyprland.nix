{ ... }:
{
  flake.modules.nixos.hyprland = { ... }: {
    programs.hyprlock.enable = true;
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  # NOTE: config/hypr/modules/autostart.lua starts awww-daemon and quickshell,
  # so import the `awww` and `quickshell` features alongside this one.
  flake.modules.homeManager.hyprland = { pkgs, ... }: {
    home.file.".config/hypr".source = ../../config/hypr;
    home.packages = [ pkgs.hyprlock ];
  };
}