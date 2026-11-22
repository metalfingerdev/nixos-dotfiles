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
  flake.modules.homeManager.hyprland = { pkgs, ... }:
    let
      # Rotates single windows (config/hypr/modules/plugins.lua). A plugin only loads into the exact
      # Hyprland it was built against: v0.1.0 is for 0.56.x, bump to the v0.57.0+1 tag with Hyprland.
      windowRotate = pkgs.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hypr-window-rotate";
        version = "0.1.0";
        src = pkgs.fetchFromGitHub {
          owner = "dox187";
          repo = "hypr-window-rotate";
          rev = "v0.1.0";
          hash = "sha256-XZMkZtcP4V1ps5HkIswUCID2rcsppcYd4wKgglsdVWM=";
        };
        # Rotated subsurfaces (Firefox's PiP video) were clamped to the unrotated tile and cut short.
        patches = [ ./hypr-window-rotate-subsurface.patch ];
        buildInputs = [ pkgs.lua5_4 ];
        makeFlags = [ "PREFIX=$(out)" "VERSION=0.1.0" ];
        meta.description = "Rotate individual Hyprland windows in 90 degree steps";
      };
    in
    {
      home.file.".config/hypr".source = ../../config/hypr;
      # A fixed path, because the Lua config is plain files and can't see store paths.
      home.file.".local/lib/hyprland/plugins/hypr-window-rotate.so".source =
        "${windowRotate}/lib/hyprland/plugins/hypr-window-rotate.so";
      home.packages = [ pkgs.hyprlock ];
    };
}