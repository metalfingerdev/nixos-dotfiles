{ self, ... }:
{
  flake.modules.nixos.stremio.home-manager.sharedModules = [ self.modules.homeManager.stremio ];

  # Local streaming server (127.0.0.1:11470) that the web player at web.stremio.com connects to.
  # stremio-service is unfree (server.js), so this relies on allowUnfree from `nix` (system/core/nix-settings.nix).
  flake.modules.homeManager.stremio = { pkgs, lib, ... }: {
    home.packages = [ pkgs.stremio-service ];

    systemd.user.services.stremio-service = {
      Unit = {
        Description = "Stremio streaming server";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe pkgs.stremio-service;
        Restart = "on-failure";
        RestartSec = 5;
      };
      # No WantedBy: started by hand (`systemctl --user start stremio-service`), not with every login.
    };

    # stremio-service copies its .desktop into ~/.config/autostart on first run unless one exists.
    # Own that path with a hidden entry, so it never starts itself at login either.
    xdg.configFile."autostart/com.stremio.service.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Stremio Service
      Hidden=true
    '';
  };
}
