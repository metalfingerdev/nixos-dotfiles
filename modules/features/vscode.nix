{ ... }:
{
  flake.modules.homeManager.vscode = { pkgs, ... }: {
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
  };
}