{ ... }:
{
  flake.modules.homeManager.quickshell = { pkgs, ... }: {
    home.file.".config/quickshell".source = ../../config/quickshell;
    home.packages = [
      pkgs.quickshell
      # the dashboard's Night light and Screen record tiles (they hide when these are missing)
      pkgs.hyprsunset
      pkgs.wf-recorder
    ];
  };
}
