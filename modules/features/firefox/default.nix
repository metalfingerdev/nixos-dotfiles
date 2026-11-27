{ self, ... }:
{
  # Firefox, as the default browser for links and HTML files.
  flake.modules.nixos.firefox = { ... }: {
    programs.firefox.enable = true;
    home-manager.sharedModules = [ self.modules.homeManager.firefox ];
  };

  flake.modules.homeManager.firefox = { lib, ... }: {
    # The package comes from programs.firefox above; this only manages the profile. Home Manager makes
    # a new, empty profile: if you already have one, set programs.firefox.profiles.default.path to its
    # folder in your host (see modules/hosts/omen/omen.nix), or you start signed out.
    programs.firefox = {
      enable = true;
      package = null;
      profiles.default = {
        isDefault = true;
        # userContent.css is ignored unless this pref is on.
        settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # The new tab page paints its wallpaper from the CSS variable --newtab-wallpaper (its own `body`
        # rule, which beats any user stylesheet). So this sets only the variable: the page's own value,
        # when the user picks a wallpaper in Firefox's customise panel, overrides it. The picture is read
        # from the store (assets/README.md), so it travels with the repo.
        userContent = ''
          @-moz-document url(about:home), url(about:newtab) {
            :root { --newtab-wallpaper: url("file://${../../../assets/firefox/marin.gif}"); }
          }
        '';
      };
    };

    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/chrome"
      "text/html" "application/xhtml+xml"
      "application/x-extension-htm" "application/x-extension-html" "application/x-extension-shtml"
      "application/x-extension-xhtml" "application/x-extension-xht"
    ] (_: "firefox.desktop");
  };
}
