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
        # The new tab wallpaper below needs Firefox's services, which AutoConfig scripts can't reach in
        # their default sandbox, so the sandbox is off (the owner agreed). The only script that runs is
        # the one below, a read-only file in the Nix store.
        package = pkgs.firefox.override {
          extraAutoConfig = ''pref("general.config.sandbox_enabled", false);'';
        };
        # The new tab page's wallpaper, for every profile. The page paints it from the CSS variable
        # --newtab-wallpaper (its own `body` rule beats any user stylesheet, so only the variable is set),
        # and a wallpaper picked in the customise panel replaces this default. The picture is served as
        # resource:// because the new tab page may not load file: images. AutoConfig skips the first line.
        autoConfig = ''
          // omen
          try {
            Components.classes["@mozilla.org/observer-service;1"]
              .getService(Components.interfaces.nsIObserverService)
              .addObserver({ observe() {
                const Cc = Components.classes, Ci = Components.interfaces;
                const dir = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile);
                dir.initWithPath("${startPage}");
                const io = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);
                io.getProtocolHandler("resource").QueryInterface(Ci.nsIResProtocolHandler)
                  .setSubstitution("nix-start-page", io.newFileURI(dir));
                const css = ":root { --newtab-wallpaper: url('resource://nix-start-page/wallpaper.gif'); }";
                Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService)
                  .loadAndRegisterSheet(io.newURI("data:text/css," + encodeURIComponent(
                    "@-moz-document url(about:home), url(about:newtab) {" + css + "}")), 1);
              } }, "final-ui-startup");
          } catch (e) {}
        '';
        # A policy, not a profile: it reaches every profile and never replaces the ones people have.
        # It covers the home page and a new window; new tabs get the wallpaper from autoConfig above.
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
