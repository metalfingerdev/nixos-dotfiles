{ ... }:
{
  flake.modules.homeManager.theme = { pkgs, ... }: {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      jetbrains-mono
      inter
      material-symbols
      adwaita-icon-theme
    ];

    home.sessionVariables = {
      XCURSOR_THEME = "macOS";
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
    };

    home.pointerCursor = {
      enable = true;
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
      hyprcursor = {
        enable = true;
        size = 24;
      };
    };
  };
}