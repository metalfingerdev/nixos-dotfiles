{ self, ... }:
{
  flake.modules.nixos.gtk.home-manager.sharedModules = [ self.modules.homeManager.gtk ];

  flake.modules.homeManager.gtk = { pkgs, ... }: {
    gtk = {
      enable = true;
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
    };
  };
}
