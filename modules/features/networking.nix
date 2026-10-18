{ ... }:
{
  flake.modules.nixos.networking = { ... }: {
    networking.networkmanager.enable = true;
    networking.firewall.enable = false;
  };
}