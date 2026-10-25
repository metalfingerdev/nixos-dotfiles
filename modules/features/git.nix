{ ... }:
{
  flake.modules.nixos.git = { ... }: {
    programs.git.enable = true;
  };

  # Identity lives in home-manager so ~/.config/git/config is visible inside
  # sandboxed apps like vscode-fhs, which can't see the host's /etc/gitconfig
  flake.modules.homeManager.git = { ... }: {
    programs.git = {
      enable = true;
      settings.user = {
        name = "mfdev";
        email = "prajwalpal@protonmail.com";
      };
    };
  };
}
