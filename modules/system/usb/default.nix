{ self, ... }:
{
  flake.modules.nixos.usb = { pkgs, ... }: {
    home-manager.sharedModules = [ self.modules.homeManager.usb ];

    # Mounting USB drives and SD cards (udiskie, below, does it as they are plugged in)
    services.udisks2.enable = true;

    # Phones and newer Kindles over MTP, and network shares and trash in file managers (gvfs)
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
