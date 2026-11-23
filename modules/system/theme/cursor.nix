{ self, ... }:
{
  flake.modules.nixos.cursor.home-manager.sharedModules = [ self.modules.homeManager.cursor ];

  flake.modules.homeManager.cursor = { pkgs, ... }: {
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
