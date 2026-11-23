{ self, ... }:
{
  flake.modules.nixos.usb = { pkgs, ... }: {
    home-manager.sharedModules = [ self.modules.homeManager.usb ];

    # Enables automounting for standard USB mass storage (older Kindles)
    services.udisks2.enable = true;

    # Enables MTP support (2024+ Kindles) and userspace virtual filesystems
    services.gvfs.enable = true;

    environment.systemPackages = [ pkgs.libmtp ];
  };

  flake.modules.homeManager.usb = {
    services.udiskie = {
      enable = true;
      # With a tray icon the service waits for tray.target, which nothing in this session starts.
      tray = "never";
    };
  };
}
