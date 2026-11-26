{ self, ... }:
{
  flake.modules.nixos.crush.home-manager.sharedModules = [ self.modules.homeManager.crush ];

  # Crush (charmbracelet): a terminal coding agent, like Claude Code, talking to the local Ollama.
  # The launcher's Coding agent action and Super+Alt+Return run `crush`; `?question` is the island's Agent.
  flake.modules.homeManager.crush = { config, lib, pkgs, ... }:
    let
      policy = import ../agent-policy/_policy.nix { home = config.home.homeDirectory; flake = lib.replaceStrings [ config.home.homeDirectory ] [ "~" ] config.home.sessionVariables.NIXOS_FLAKE; };
    in {
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
      # The web, through the local SearXNG (features/searxng). Every tool's description takes room in the
      # 8k window, so the lite descriptions, and only searching and reading a page.
      mcp.searxng = {
        type = "stdio";
        command = "${pkgs.mcp-searxng}/bin/mcp-searxng";
        env = { SEARXNG_URL = "http://127.0.0.1:8888"; SEARXNG_LITE_TOOLS = "true"; };
        enabled_tools = [ "searxng_web_search" "web_url_read" ];
      };
      permissions = {
        # reading never asks
        allowed_tools = [ "view" "ls" "glob" "grep" ];
        # One deny list for every agent (features/agent-policy): these always ask, and -y blocks them.
        blocked_commands = policy.commands;
      };
      options = {
        # The memory file both agents share (features/agent-memory)
        global_context_paths = [ "${config.home.homeDirectory}/.local/share/jarvis/memory.md" ];
        disable_metrics = true;
        # Its default puts a "Generated with Crush" line and a trailer in commits and PRs, and GitHub lists
        # a trailer's name as a contributor.
        attribution = { trailer_style = "none"; generated_with = false; };
      };
    };
  };
}
