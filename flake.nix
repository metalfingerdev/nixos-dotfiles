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

    # Zen, the browser (Gecko: Firefox with vertical tabs and a compact mode of its own), with its
    # Home Manager module: modules/features/zen. nixpkgs doesn't package it.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Liquid glass on windows and the island (modules/features/hyprland). Pinned to a release tag: each
    # is written for one Hyprland, and `main` follows the newest, so a plain update could break the build.
    hyprglass = { url = "github:hyprnux/hyprglass/v1.2.0"; flake = false; };

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