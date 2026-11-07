{ ... }:
{
  flake.modules.nixos.git = { ... }: {
    programs.git.enable = true;
  };

  # Enabled in home-manager so ~/.config/git/config is visible inside
  # sandboxed apps like vscode-fhs, which can't see the host's /etc/gitconfig.
  # Identity is set per user.
  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git.enable = true;
    # GitHub is reached over SSH (see ssh.nix); there is no HTTPS credential helper, so rewrite
    # https remote URLs to SSH instead of failing on a password prompt.
    programs.git.settings.url."git@github.com:".insteadOf = "https://github.com/";
    home.packages = [ pkgs.gh ];
  };
}
