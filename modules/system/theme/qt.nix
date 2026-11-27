{ self, ... }:
{
  # Qt apps (VLC, qimgv, LibreOffice) in the island's teal, as gtk.nix does for GTK: qt6ct picks the style and
  # fonts, Kvantum draws the widgets and carries the colours (so qt6ct's own palette stays off). The colours are Config.qml's teal palette (config/quickshell/modules/components);
  # a different accent in the island doesn't reach Qt apps, which would need this file changed too.
  flake.modules.nixos.qt.home-manager.sharedModules = [ self.modules.homeManager.qt ];

  flake.modules.homeManager.qt = { lib, pkgs, ... }:
    let
      # Config.qml's teal: surface, container, high, primary, onPrimary, secondary, onSecondary
      surface = "#0e1514";
      container = "#1a2120";
      high = "#252b2a";
      primary = "#80d5c8";
      onPrimary = "#003731";
      secondary = "#334b47";
      text = "#dde4e2";
      dim = "#9aa5a2";
    in {
      home.packages = [ pkgs.kdePackages.qt6ct pkgs.libsForQt5.qt5ct ];

      qt = {
        enable = true;
        platformTheme.name = "qtct";
        style.name = "kvantum";
        kvantum = {
          enable = true;
          settings.General.theme = "Marin";
        };
        qt6ctSettings = {
          Appearance = { style = "kvantum"; custom_palette = false; color_scheme_path = ""; standard_dialogs = "default"; };
          Fonts = { general = "Inter,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; fixed = "JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; };
        };
        qt5ctSettings = {
          Appearance = { style = "kvantum"; custom_palette = false; color_scheme_path = ""; standard_dialogs = "default"; };
          Fonts = { general = "Inter,11,-1,5,50,0,0,0,0,0"; fixed = "JetBrains Mono,10,-1,5,50,0,0,0,0,0"; };
        };
      };

      # The theme itself (qt.kvantum.themes takes packages): no SVG of its own, so Kvantum draws its built-in
      # one, tinted by these colours
      xdg.configFile."Kvantum/Marin/Marin.kvconfig".text = lib.generators.toINI { } {
        General = {
          author = "marin";
          comment = "The island's teal";
          composite = true;
          translucent_windows = false;
          blurring = false;
          reduce_window_opacity = 0;
          spread_menuitems = true;
          menu_shadow_depth = 6;
        };
        GeneralColors = {
          "window.color" = surface;
          "base.color" = surface;
          "alt.base.color" = container;
          "button.color" = container;
          "light.color" = high;
          "mid.light.color" = high;
          "dark.color" = surface;
          "mid.color" = secondary;
          "highlight.color" = primary;
          "inactive.highlight.color" = secondary;
          "text.color" = text;
          "window.text.color" = text;
          "button.text.color" = text;
          "disabled.text.color" = dim;
          "tooltip.base.color" = container;
          "tooltip.text.color" = text;
          "highlight.text.color" = onPrimary;
          "link.color" = primary;
          "link.visited.color" = primary;
        };
      };
    };
}
