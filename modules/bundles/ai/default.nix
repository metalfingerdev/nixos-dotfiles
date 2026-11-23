{ self, ... }:
{
  flake.modules.nixos.ai.imports = with self.modules.nixos; [
    ollama
    open-webui
    searxng
    crush
  ];
}
