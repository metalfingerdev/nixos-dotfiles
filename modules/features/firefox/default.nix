{ self, ... }:
{
  # Firefox, as the default browser for links and HTML files.
  flake.modules.nixos.firefox = { ... }: {
    programs.firefox.enable = true;
    home-manager.sharedModules = [ self.modules.homeManager.firefox ];
  };

  flake.modules.homeManager.firefox = { config, lib, ... }: {
    # The package comes from programs.firefox above; this only manages the profile.
    programs.firefox = {
      enable = true;
      package = null;
      profiles.default = {
        isDefault = true;
        # userContent.css is ignored unless this pref is on.
        settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # The new tab page's default wallpaper: zero specificity and no !important, so a wallpaper the
        # user picks in Firefox's own customise panel wins over it. The URL is relative to the stylesheet, so the picture sits
        # next to it (home.file below). From assets/ (see assets/README.md), so it travels with the repo.
        userContent = ''
          @-moz-document url(about:home), url(about:newtab) {
            :where(body) { background: url("wallpaper.gif") center / cover no-repeat fixed; }
          }
        '';
      };
    };
    home.file."${config.programs.firefox.configPath}/${config.programs.firefox.profiles.default.path}/chrome/wallpaper.gif".source = ../../../assets/firefox/marin.gif;

    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/chrome"
      "text/html" "application/xhtml+xml"
      "application/x-extension-htm" "application/x-extension-html" "application/x-extension-shtml"
      "application/x-extension-xhtml" "application/x-extension-xht"
    ] (_: "firefox.desktop");
  };
}
