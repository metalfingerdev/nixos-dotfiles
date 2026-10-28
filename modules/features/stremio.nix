{ ... }:
{
  # Local streaming server (127.0.0.1:11470) that the web player at web.stremio.com connects to.
  # stremio-service is unfree (server.js), so this relies on allowUnfree from the `base` feature.
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
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # stremio-service copies its .desktop into ~/.config/autostart on first run unless one exists.
    # Own that path with a hidden entry so the systemd unit above is the only launcher.
    xdg.configFile."autostart/com.stremio.service.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Stremio Service
      Hidden=true
    '';
  };
}
