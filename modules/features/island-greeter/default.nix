{ inputs, ... }:
{
  # Optional: the island's own login screen (config/quickshell/greeter, a Quickshell program run by greetd
  # inside cage as the greeter user) in place of ly. No host takes it by default; to try it, add
  # `island-greeter` to a host's modules list (hosts/omen), and remove it to go back to ly.
  flake.modules.nixos.island-greeter = { lib, pkgs, ... }:
    let
      # WebP is a Qt image plugin that nixpkgs' quickshell lacks (features/quickshell wraps it the same way)
      quickshell = pkgs.symlinkJoin {
        name = "quickshell-greeter";
        paths = [ pkgs.quickshell ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/quickshell \
            --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}
        '';
      };
      user = "admin";
      # The session ly starts: Hyprland under UWSM
      sessionCommand = [ "uwsm" "start" "hyprland-uwsm.desktop" ];

      # The login screen, with a way out: if Quickshell doesn't come up (a broken QML change, no GPU for
      # cage) or the greeter falls twice in a row, the text greeter takes over, so a bug here can never
      # lock you out. A finished login ends the greeter with a signal, which doesn't count as a fall.
      start = pkgs.writeShellScript "island-greeter" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH
        export GREETER_USER=${user}
        export GREETER_SESSION='${builtins.toJSON sessionCommand}'
        run=''${XDG_RUNTIME_DIR:?}
        export GREETER_READY="$run/island-greeter-ready"
        falls="$run/island-greeter-falls"
        text() {
          exec ${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd "${lib.concatStringsSep " " sessionCommand}"
        }
        rm -f "$GREETER_READY"
        if [ "$(cat "$falls" 2> /dev/null || echo 0)" -ge 2 ]; then
          rm -f "$falls"
          echo "island-greeter: it fell twice, the text greeter instead" >&2
          text
        fi
        ${quickshell}/bin/quickshell -p ${inputs.quickshell}/greeter &
        pid=$!
        for _ in $(seq 100); do
          [ -e "$GREETER_READY" ] && break
          kill -0 "$pid" 2> /dev/null || break
          sleep 0.1
        done
        if [ -e "$GREETER_READY" ]; then
          status=0
          wait "$pid" || status=$?
          case $status in
            0 | 130 | 143) rm -f "$falls" ;;
            *) echo $(( $(cat "$falls" 2> /dev/null || echo 0) + 1 )) > "$falls" ;;
          esac
          exit "$status"
        fi
        echo "island-greeter: Quickshell didn't come up, the text greeter instead" >&2
        kill "$pid" 2> /dev/null
        wait "$pid" 2> /dev/null
        text
      '';
    in {
      services.displayManager.ly.enable = lib.mkForce false;
      services.greetd = {
        enable = true;
        settings.default_session = {
          # cage gives the greeter a Wayland session of its own, on every screen; software rendering is
          # allowed: a slow login screen beats none
          command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.coreutils}/bin/env WLR_RENDERER_ALLOW_SOFTWARE=1 ${lib.getExe pkgs.cage} -s -d -m extend -- ${start}";
          user = "greeter";
        };
      };
      # the keyring unlocks with the login password, as it does under ly
      security.pam.services.greetd.enableGnomeKeyring = true;
    };
}
