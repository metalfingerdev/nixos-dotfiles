{ self, ... }:
{
  # Adwaita icons for GTK apps (Thunar, Blueman, pavucontrol), and the fonts of system/theme/fonts.nix
  # named where GTK keeps its own setting instead of asking fontconfig. Qt apps take the same through GTK
  # (system/session names the desktop GNOME too, which makes Qt follow GTK's settings).
  flake.modules.nixos.gtk.home-manager.sharedModules = [ self.modules.homeManager.gtk ];

  flake.modules.homeManager.gtk = { pkgs, ... }: {
    gtk = {
      enable = true;
      font = { name = "Inter"; size = 11; };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
    };
    # GTK 4 and libadwaita apps read these through the settings portal
    dconf.settings."org/gnome/desktop/interface" = {
      monospace-font-name = "JetBrains Mono 10";
      document-font-name = "Source Serif 4 11";
    };
  };
}
