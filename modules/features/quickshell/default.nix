{ inputs, self, ... }:
{
  flake.modules.nixos.quickshell.home-manager.sharedModules = [ self.modules.homeManager.quickshell ];

  flake.modules.homeManager.quickshell = { pkgs, ... }:
    let
      # WebP and friends are Qt image plugins, which nixpkgs' quickshell doesn't carry. Added by a
      # wrapper, not an override: that would rebuild quickshell from source on every nixpkgs update.
      quickshell = pkgs.symlinkJoin {
        name = "quickshell-with-imageformats";
        paths = [ pkgs.quickshell ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in quickshell qs; do
            wrapProgram $out/bin/$bin \
              --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}
          done
        '';
      };
    in
    {
      home.file.".config/quickshell".source = inputs.quickshell;
      home.packages = [
        quickshell
        # the dashboard's Night light and Screen record tiles (they hide when these are missing)
        pkgs.hyprsunset
        pkgs.wf-recorder
        # the clipboard history (ClipHistory: kept in the runtime folder, so in memory only)
        pkgs.cliphist
        pkgs.wl-clipboard
        # the island's sounds (Sounds: message-new-instant, dialog-warning, power-plug...)
        pkgs.sound-theme-freedesktop
        # the Colours view's eyedropper: an accent from anywhere on the screen (Toggles.pickColour)
        pkgs.hyprpicker
      ];

      # The shell is the lock screen, the idle timer (dim, lock, suspend) and the notification
      # server, so it must come back if it falls: on a crash systemd starts it again, and it locks
      # again at once if it was locked (Lock.qml, with Hyprland's allow_session_lock_restore).
      # Apps it starts go in scopes of their own (Toggles.launch), so a restart leaves them open.
      # Hyprland starts and restarts it through this unit (config/hypr/session.lua).
      systemd.user.services.quickshell = {
        Unit = {
          Description = "Quickshell: the island, notifications, idle and the lock screen";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          # The log rule: Qt's text-input-v3 warns each time the island lets go of the keyboard with a
          # text field focused (Hyprland has moved focus away before Qt switches text input off).
          # Harmless, and it was most of the log. A pragma in shell.qml comes too late for logging.
          ExecStart = "${quickshell}/bin/quickshell --log-rules qt.qpa.wayland.textinput.warning=false";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
