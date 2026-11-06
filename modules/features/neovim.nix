{ ... }:
{
  flake.modules.homeManager.neovim = { pkgs, ... }: {
    home.file.".config/nvim".source = ../../config/nvim;

    home.packages = with pkgs; [
      neovim
      ripgrep
      nil
      nixpkgs-fmt
      nodejs
      gcc
    ];
  };
}