{ self, ... }:
{
  # awww, the wallpaper daemon. hypr's session.lua starts it with the session, and the island sets
  # images through it (Wallpaper.qml); it restores the last one by itself at the next login.
  flake.modules.nixos.awww.home-manager.sharedModules = [ self.modules.homeManager.awww ];

  flake.modules.homeManager.awww = { pkgs, ... }: {
    home.packages = [ pkgs.awww ];
  };
}