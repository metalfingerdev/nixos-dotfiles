{ self, ... }:
{
  # Everyday desktop apps. Firefox is the default browser, VLC the video player, qimgv the image viewer, zathura the PDF viewer.
  flake.modules.nixos.apps.imports = with self.modules.nixos; [
    firefox
    zen                 # alongside Firefox: vertical tabs, Vim keys (Tridactyl)
    libreoffice
    vlc
    qimgv               # image viewer
    zathura             # PDF viewer
    stremio
    bittorrent
    calibre
  ];
}
