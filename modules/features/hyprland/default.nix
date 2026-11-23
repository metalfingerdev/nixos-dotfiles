{ inputs, self, ... }:
{
  flake.modules.nixos.hyprland = { ... }: {
    # config/hypr/modules/autostart.lua starts awww-daemon and quickshell.
    imports = with self.modules.nixos; [ awww quickshell ];
    home-manager.sharedModules = [ self.modules.homeManager.hyprland ];
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  flake.modules.homeManager.hyprland = { lib, pkgs, ... }:
    let
      # Rotates single windows (config/hypr/modules/plugins.lua). Each release is tagged for the
      # Hyprland it builds against (v0.57.0+1 is for 0.57), and a plugin only loads into that one. When
      # nixpkgs moves Hyprland on, the plugin is left out with a warning, and its binds with it, until
      # `version` and `hash` here follow (github.com/dox187/hypr-window-rotate/tags).
      version = "0.57.0+1";
      matches = lib.versions.majorMinor version == lib.versions.majorMinor pkgs.hyprland.version;
      src = pkgs.fetchFromGitHub {
        owner = "dox187";
        repo = "hypr-window-rotate";
        rev = "v${version}";
        hash = "sha256-JMZjrP8D5CQ7IE9CVh6g5BCx8GVK9C8Ff5KlE46PBmw=";
      };
      # Rotated subsurfaces (Firefox's PiP video) were clamped to the unrotated tile and cut short.
      subsurfaceFix = self.lib.optionalPatch {
        name = "hypr-window-rotate";
        patch = ./hypr-window-rotate-subsurface.patch;
        file = "${src}/src/main.cpp";
      };
      windowRotate = pkgs.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hypr-window-rotate";
        inherit version src;
        inherit (subsurfaceFix) patches;
        buildInputs = [ pkgs.lua5_4 ];
        makeFlags = [ "PREFIX=$(out)" "VERSION=${version}" ];
        meta.description = "Rotate individual Hyprland windows in 90 degree steps";
      };
    in
    {
      warnings = if matches then subsurfaceFix.warnings else [
        "hypr-window-rotate ${version} is for Hyprland ${lib.versions.majorMinor version}, but nixpkgs has ${pkgs.hyprland.version}, so it's left out (no window rotation). Bump its version and hash in modules/features/hyprland."
      ];
      home.file.".config/hypr".source = inputs.hypr;
      # A fixed path, because the Lua config is plain files and can't see store paths. Missing while
      # the plugin is left out; plugins.lua then skips it.
      home.file.".local/lib/hyprland/plugins/hypr-window-rotate.so" = lib.mkIf matches {
        source = "${windowRotate}/lib/hyprland/plugins/hypr-window-rotate.so";
      };
    };
}