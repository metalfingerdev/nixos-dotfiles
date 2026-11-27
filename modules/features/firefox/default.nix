{ self, ... }:
{
  # Firefox, as the default browser for links and HTML files.
  flake.modules.nixos.firefox = { pkgs, ... }:
    let
      # The start page: the wallpaper, full screen. The picture sits beside the page in one store
      # folder, so the relative URL works (assets/README.md says where it comes from).
      startPage = pkgs.linkFarm "firefox-start-page" {
        "index.html" = pkgs.writeText "index.html" ''
          <!doctype html>
          <meta charset="utf-8">
          <title>New tab</title>
          <style>
            html { height: 100%; background: #000 url("wallpaper.gif") center / cover no-repeat fixed; }
          </style>
        '';
        "wallpaper.gif" = ../../../assets/firefox/marin.gif;
      };
    in {
      programs.firefox = {
        enable = true;
        # A policy, not a profile: it reaches every profile and never replaces the ones people have.
        # It covers the home page and a new window, not Ctrl+T (Firefox has no policy for that).
        policies.Homepage = {
          URL = "file://${startPage}/index.html";
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
