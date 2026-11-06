{ ... }:
{
  flake.modules.homeManager.quickshell = { pkgs, ... }:
    let
      # WebP and friends are Qt image plugins, which nixpkgs' quickshell doesn't carry. Added by a
      # wrapper, not an override: that would rebuild quickshell from source on every nixpkgs update.
      quickshell = pkgs.symlinkJoin {
        name = "quickshell-with-imageformats";
        paths = [ pkgs.quickshell ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in quickshell qs; do
            wrapProgram $out/bin/$bin \
              --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}
          done
        '';
      };
    in
    {
      home.file.".config/quickshell".source = ../../config/quickshell;
      home.packages = [
        quickshell
        # the dashboard's Night light and Screen record tiles (they hide when these are missing)
        pkgs.hyprsunset
        pkgs.wf-recorder
      ];
    };
}
