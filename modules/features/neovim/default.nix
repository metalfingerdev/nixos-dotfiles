{ inputs, self, ... }:
{
  # Neovim with the nvim repo's config (read-only in ~/.config/nvim). The packages beside it are what
  # that config calls: ripgrep to search, nil and nixpkgs-fmt for Nix, node and gcc to build plugins, tree-sitter
  # (the CLI) and gcc to build the parsers nvim-treesitter installs.
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
      tree-sitter
    ];
  };
}