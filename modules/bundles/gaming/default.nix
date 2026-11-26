{ self, ... }:
{
  # Games. The home host uses it; add it to any host's list.
  flake.modules.nixos.gaming.imports = with self.modules.nixos; [
    steam
  ];
}
