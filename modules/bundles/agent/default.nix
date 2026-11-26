{ self, ... }:
{
  # The local agents: models on this machine (Ollama), the web through SearXNG, Crush, the island's agent
  # and the memory file Crush and Claude Code share. Personal, so only omen lists it. Everything listens on
  # localhost only; the models need an NVIDIA GPU (features/ollama builds CUDA for omen's GTX 1650 alone:
  # change it for another). The cloud agents are the `ai` bundle.
  flake.modules.nixos.agent.imports = with self.modules.nixos; [
    ollama
    searxng
    crush
    nilo-agent
    agent-memory
  ];
}
