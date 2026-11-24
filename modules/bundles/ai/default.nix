{ self, ... }:
{
  flake.modules.nixos.ai.imports = with self.modules.nixos; [
    ollama
    searxng
    crush
    nilo-agent
  ];
}
