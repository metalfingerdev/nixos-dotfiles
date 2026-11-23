{ inputs, self, ... }:
{
  flake.modules.nixos.hyprland = { ... }: {
    # config/hypr/modules/autostart.lua starts awww-daemon and quickshell: import those too.
    home-manager.sharedModules = [ self.modules.homeManager.hyprland ];
    programs.hyprlock.enable = true;
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  flake.modules.homeManager.hyprland = { lib, pkgs, ... }:
    let
      # Rotates single windows (config/hypr/modules/plugins.lua). A plugin only loads into the exact
      # Hyprland it was built against, so a nixpkgs update that moves Hyprland stops the build here
      # instead of leaving the rotate binds dead after a reboot.
      rotateFor = "0.57";
      windowRotate =
        assert lib.assertMsg (lib.versions.majorMinor pkgs.hyprland.version == rotateFor)
          "hypr-window-rotate is built for Hyprland ${rotateFor}.x, but nixpkgs has ${pkgs.hyprland.version}: bump its rev, hash and rotateFor in modules/features/hyprland (tags: github.com/dox187/hypr-window-rotate/tags).";
        pkgs.hyprlandPlugins.mkHyprlandPlugin {
          pluginName = "hypr-window-rotate";
          version = "0.57.0+1";
          src = pkgs.fetchFromGitHub {
            owner = "dox187";
            repo = "hypr-window-rotate";
            rev = "v0.57.0+1";
            hash = "sha256-JMZjrP8D5CQ7IE9CVh6g5BCx8GVK9C8Ff5KlE46PBmw=";
          };
          # Rotated subsurfaces (Firefox's PiP video) were clamped to the unrotated tile and cut short.
          patches = [ ./hypr-window-rotate-subsurface.patch ];
          buildInputs = [ pkgs.lua5_4 ];
          makeFlags = [ "PREFIX=$(out)" "VERSION=0.57.0+1" ];
          meta.description = "Rotate individual Hyprland windows in 90 degree steps";
        };
    in
    {
      home.file.".config/hypr".source = inputs.hypr;
      # A fixed path, because the Lua config is plain files and can't see store paths.
      home.file.".local/lib/hyprland/plugins/hypr-window-rotate.so".source =
        "${windowRotate}/lib/hyprland/plugins/hypr-window-rotate.so";
      home.packages = [ pkgs.hyprlock ];
    };
}