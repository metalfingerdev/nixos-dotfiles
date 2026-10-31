{ ... }:
let
  # qBittorrent randomizes its port on first run, which wouldn't match the firewall rule below.
  port = 51413;
in
{
  # Without inbound peer connections, torrents with few seeders stall and seeding barely works.
  flake.modules.nixos.bittorrent = { ... }: {
    networking.firewall.allowedTCPPorts = [ port ];
    networking.firewall.allowedUDPPorts = [ port ];
  };

  flake.modules.homeManager.bittorrent = { pkgs, lib, ... }: {
    home.packages = [ pkgs.qbittorrent ];

    # qBittorrent rewrites this file at runtime, so seed it once rather than symlinking it from the store.
    home.activation.seedQbittorrentConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      conf="$HOME/.config/qBittorrent/qBittorrent.conf"
      if [ ! -e "$conf" ]; then
        run install -Dm644 ${pkgs.writeText "qBittorrent.conf" ''
          [BitTorrent]
          Session\Port=${toString port}
        ''} "$conf"
      fi
    '';
  };
}
