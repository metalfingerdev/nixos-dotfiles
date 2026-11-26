{ self, ... }:
{
  # The local AI stack: personal, so only omen lists it. Everything listens on localhost only; the
  # models need an NVIDIA GPU (features/ollama builds CUDA for omen's GTX 1650 alone: change it for another).
  flake.modules.nixos.ai.imports = with self.modules.nixos; [
    ollama
    searxng
    crush
    nilo-agent
    agent-memory
  ];
}
