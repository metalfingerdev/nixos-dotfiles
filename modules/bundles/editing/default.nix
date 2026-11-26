{ self, ... }:
{
  # Audio, video and image editors: large, so a host picks this bundle only if it wants them.
  flake.modules.nixos.editing.imports = with self.modules.nixos; [
    audacity
    kdenlive
    handbrake
    gimp
  ];
}
