{ self, ... }:
{
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
