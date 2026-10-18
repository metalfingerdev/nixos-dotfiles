{ ... }:
{
  flake.modules.homeManager.theme = { pkgs, ... }: {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      maple-mono.NF
      inter
      material-symbols
      papirus-icon-theme
    ];

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
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