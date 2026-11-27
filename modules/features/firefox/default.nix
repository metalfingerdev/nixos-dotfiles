{ self, ... }:
{
  # Firefox, as the default browser for links and HTML files.
  flake.modules.nixos.firefox = { pkgs, ... }:
    let
      # The start page: the wallpaper, full screen. The store folder repeats the repo's layout, so the
      # page's relative link to the picture works there and when index.html is opened from the repo
      # (assets/README.md says where the picture comes from).
      startPage = pkgs.linkFarm "firefox-start-page" {
        "modules/features/firefox/index.html" = ./index.html;
        "assets/firefox/marin.gif" = ../../../assets/firefox/marin.gif;
      };
    in {
      programs.firefox = {
        enable = true;
        # A policy, not a profile: it reaches every profile and never replaces the ones people have.
        # It covers the home page and a new window, not Ctrl+T (Firefox has no policy for that).
        policies.Homepage = {
          URL = "file://${startPage}/modules/features/firefox/index.html";
          StartPage = "homepage";
        };
      };
      home-manager.sharedModules = [ self.modules.homeManager.firefox ];
    };

  flake.modules.homeManager.firefox = { lib, ... }: {
    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/chrome"
      "text/html" "application/xhtml+xml"
      "application/x-extension-htm" "application/x-extension-html" "application/x-extension-shtml"
      "application/x-extension-xhtml" "application/x-extension-xht"
    ] (_: "firefox.desktop");
  };
}
