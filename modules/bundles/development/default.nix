{ self, ... }:
{
  # Programming tools. Each person's git identity is in their own module (modules/users/), not here.
  flake.modules.nixos.development.imports = with self.modules.nixos; [
    git
    lazygit
    neovim
    vscode
    python3
    webdev
  ];
}
