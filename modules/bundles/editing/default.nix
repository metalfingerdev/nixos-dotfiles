{ self, ... }:
{
  flake.modules.nixos.editing.imports = with self.modules.nixos; [
    audacity
    kdenlive
    handbrake
    gimp
  ];
}
