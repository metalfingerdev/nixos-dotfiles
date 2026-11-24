{ self, ... }:
{
  flake.modules.nixos.nilo-agent.home-manager.sharedModules = [ self.modules.homeManager.nilo-agent ];

  # Nihil-Shell's agent (agent.py, MIT), kept here as our own: the island's Agent (config/quickshell,
  # services/Agent.qml) runs `nilo-agent` and talks JSON lines to it. Kept at its Chat level, which the
  # island never raises: the model may search (SearXNG) and read pages, look up this computer and open
  # apps. Its other levels (files, commands, the desktop) are Crush's job.
  flake.modules.homeManager.nilo-agent = { pkgs, lib, osConfig, ... }:
    let
      ollama = osConfig.services.ollama;
      config = pkgs.writeText "nilo.json" (builtins.toJSON {
        ollama = "http://${ollama.host}:${toString ollama.port}";
        language = "en";
        # Ollama's own list and window: features/ollama stays the one place to change them
        models = map (tag: { inherit tag; label = tag; }) ollama.loadModels;
        contextLength = lib.toInt ollama.environmentVariables.OLLAMA_CONTEXT_LENGTH;
        searxng = "http://127.0.0.1:8888";
        systemctl = "${osConfig.systemd.package}/bin/systemctl";
        journalctl = "${osConfig.systemd.package}/bin/journalctl";
        ollamaUnit = "ollama.service";
        host = osConfig.networking.hostName;
        flake = "~/nixos-dotfiles";
      });
    in
    {
      home.packages = [
        (pkgs.writeShellScriptBin "nilo-agent" ''
          exec ${pkgs.python3}/bin/python3 -I ${./agent.py} --config ${config} \
            --state "''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/agent.json" "$@"
        '')
      ];
    };
}
