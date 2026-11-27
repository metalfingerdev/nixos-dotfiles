{ self, inputs, ... }:
{
  flake.modules.nixos.nilo-agent.home-manager.sharedModules = [ self.modules.homeManager.nilo-agent ];

  # The island's Agent (config/quickshell, services/Agent.qml) runs `nilo-agent` and talks JSON lines to it.
  # The program is the nilo-agent input (a fork of Nihil-Shell's Nilo, MIT). All three of its levels are
  # offered; the island asks before every change, command and desktop action, and its setting (Chat by
  # default) lives in ~/.local/state/quickshell/agent.json. The tool paths below are what the levels need.
  flake.modules.homeManager.nilo-agent = { pkgs, lib, osConfig, ... }@hm:
    let
      ollama = osConfig.services.ollama;
      config = pkgs.writeText "nilo.json" (builtins.toJSON {
        ollama = "http://${ollama.host}:${toString ollama.port}";
        language = "en";
        # Ollama's own list and window: features/ollama stays the one place to change them
        models = map (tag: { inherit tag; label = tag; }) ollama.loadModels;
        contextLength = lib.toInt ollama.environmentVariables.OLLAMA_CONTEXT_LENGTH;
        searxng = "http://127.0.0.1:8888";
        ddgr = "${pkgs.ddgr}/bin/ddgr";
        git = "${pkgs.git}/bin/git";
        bash = "${pkgs.bash}/bin/bash";
        bwrap = "${pkgs.bubblewrap}/bin/bwrap";
        hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
        wtype = "${pkgs.wtype}/bin/wtype";
        playerctl = "${pkgs.playerctl}/bin/playerctl";
        grim = "${pkgs.grim}/bin/grim";
        wlrctl = "${pkgs.wlrctl}/bin/wlrctl";
        terminal = "kitty";
        # No Co-authored-by trailer on its commits: they stay mine
        coauthor = null;
        context = "${inputs.nilo-agent}/nilo.md";
        systemctl = "${osConfig.systemd.package}/bin/systemctl";
        journalctl = "${osConfig.systemd.package}/bin/journalctl";
        ollamaUnit = "ollama.service";
        host = osConfig.networking.hostName;
        flake = lib.replaceStrings [ hm.config.home.homeDirectory ] [ "~" ] hm.config.home.sessionVariables.NIXOS_FLAKE;
      });
    in
    {
      home.packages = [
        (pkgs.writeShellScriptBin "nilo-agent" ''
          exec ${pkgs.python3}/bin/python3 -I ${inputs.nilo-agent}/agent.py --config ${config} \
            --state "''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/agent.json" "$@"
        '')
      ];
    };
}
