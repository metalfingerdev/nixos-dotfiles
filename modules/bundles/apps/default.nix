{ self, ... }:
{
  flake.modules.nixos.apps.imports = with self.modules.nixos; [
    firefox
    libreoffice
    vlc
    stremio
    bittorrent
    calibre
  ];
}
