{
  description = "NixOS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dotfiles, each its own repo (checked out in config/, ignored here). Only their files are used.
    hypr = { url = "github:metalfingerdev/hypr"; flake = false; };
    kitty = { url = "github:metalfingerdev/kitty"; flake = false; };
    nvim = { url = "github:metalfingerdev/nvim"; flake = false; };
    quickshell = { url = "github:metalfingerdev/quickshell"; flake = false; };
    yazi = { url = "github:metalfingerdev/yazi"; flake = false; };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}