{ self, ... }:
{
  flake.modules.nixos.apps.imports = with self.modules.nixos; [
    firefox
    zen                 # alongside Firefox: vertical tabs, Vim keys (Tridactyl)
    libreoffice
    vlc
    stremio
    bittorrent
    calibre
  ];
}
