{ inputs, self, ... }:
{
  flake.modules.nixos.neovim.home-manager.sharedModules = [ self.modules.homeManager.neovim ];

  flake.modules.homeManager.neovim = { pkgs, ... }: {
    home.file.".config/nvim".source = inputs.nvim;

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