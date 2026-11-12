{ ... }:
{
  flake.modules.nixos.usb = { pkgs, ... }: {
    # Enables automounting for standard USB mass storage (older Kindles)
    services.udisks2.enable = true;

    # Enables MTP support (2024+ Kindles) and userspace virtual filesystems
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      libmtp
      udiskie    # Lightweight automounter tray/daemon for Hyprland
      calibre    # Best tool for converting EPUB -> AZW3 and sending to Kindle
    ];
  };
}

