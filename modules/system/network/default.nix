{ ... }:
{
  # NetworkManager (the island's Network view, nmcli) and the firewall: nothing is reachable from outside
  # unless a feature opens a port (bittorrent does). Users get the networkmanager group in their module.
  flake.modules.nixos.network = { ... }: {
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
  };
}