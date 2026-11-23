{ self, ... }:
{
  flake.modules.nixos.development.imports = with self.modules.nixos; [
    git
    lazygit
    neovim
    vscode
    claude-code
    python3
    webdev
  ];
}
