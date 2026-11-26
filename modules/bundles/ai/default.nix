{ self, ... }:
{
  # Cloud coding agents: Claude Code and Google's Antigravity (editor and CLI). Personal and unfree, so only
  # omen lists it. The local ones are the `agents` bundle.
  flake.modules.nixos.ai.imports = with self.modules.nixos; [
    claude-code
    antigravity
  ];
}
