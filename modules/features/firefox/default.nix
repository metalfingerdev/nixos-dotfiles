{ self, ... }:
{
  flake.modules.nixos.firefox = { ... }: {
    programs.firefox.enable = true;
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
