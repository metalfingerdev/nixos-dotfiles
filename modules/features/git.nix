{ ... }:
{
  flake.modules.nixos.git = { ... }: {
    programs.git.enable = true;
  };

  # Enabled in home-manager so ~/.config/git/config is visible inside
  # sandboxed apps like vscode-fhs, which can't see the host's /etc/gitconfig.
  # Identity is set per user.
  flake.modules.homeManager.git = { ... }: {
    programs.git.enable = true;
  };
}
