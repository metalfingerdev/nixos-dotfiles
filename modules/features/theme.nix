{ ... }:
{
  flake.modules.homeManager.theme = { pkgs, ... }: {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      maple-mono.NF
      inter
      material-symbols
      adwaita-icon-theme
    ];

    home.sessionVariables = {
      GTK_THEME = "Papirus";
      XCURSOR_THEME = "macOS";
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwatia";
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