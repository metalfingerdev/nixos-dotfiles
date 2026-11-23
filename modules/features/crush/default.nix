{ self, ... }:
{
  flake.modules.nixos.crush.home-manager.sharedModules = [ self.modules.homeManager.crush ];

  # Crush (charmbracelet): a terminal coding agent, like Claude Code, talking to the local Ollama.
  # The launcher's `?question` and its Agent action, and Super+Alt+Return, all run `crush`.
  flake.modules.homeManager.crush = { pkgs, ... }: {
    home.packages = [ pkgs.crush ];

    xdg.configFile."crush/crush.json".text = builtins.toJSON {
      providers.ollama = {
        name = "Ollama";
        base_url = "http://127.0.0.1:11434/v1/";
        type = "openai-compat";
        models = [
          # context_window matches OLLAMA_CONTEXT_LENGTH in features/ollama.
          { id = "qwen3.5:2b"; name = "Qwen 3.5 2B"; context_window = 8192; default_max_tokens = 2048; }
        ];
      };
      options.disable_metrics = true;
    };
  };
}
