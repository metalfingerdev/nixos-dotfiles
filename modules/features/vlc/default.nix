{ self, ... }:
{
  # VLC, as the default player for MP4 and MKV.
  flake.modules.nixos.vlc.home-manager.sharedModules = [ self.modules.homeManager.vlc ];

  flake.modules.homeManager.vlc = { pkgs, ... }: {
    home.packages = [ pkgs.vlc ];
    xdg.mimeApps.defaultApplications = {
      "video/mp4" = "vlc.desktop";
      "video/matroska" = "vlc.desktop";
    };
  };
}
