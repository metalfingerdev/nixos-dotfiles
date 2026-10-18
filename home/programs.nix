{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs; # Fixes marketplace extension binary crashes
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        mkhl.direnv
      ];
    };
  };

  programs.ssh.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "mfdev";
      email = "prajwalpal@protonmail.com";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo I use NixOS btw";
    };
  };
}