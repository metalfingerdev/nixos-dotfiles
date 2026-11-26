{ self, ... }:
{
  # A whole graphical session: core, then the login, Hyprland with the island, hardware services and the
  # look. A host adds its GPU driver and bundles.
  flake.modules.nixos.desktop.imports = with self.modules.nixos; [
    core
    session
    hyprland
    audio
    network
    bluetooth
    power
    usb
    theme
  ];
}
