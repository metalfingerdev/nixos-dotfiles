{ self, ... }:
{
  flake.modules.nixos.desktop.imports = with self.modules.nixos; [
    core
    session
    hyprland
    awww
    quickshell
    audio
    network
    bluetooth
    power
    usb
    theme
  ];
}
