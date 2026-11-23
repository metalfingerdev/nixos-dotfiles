{ self, ... }:
{
  flake.modules.nixos.gaming.imports = with self.modules.nixos; [
    steam
  ];
}
