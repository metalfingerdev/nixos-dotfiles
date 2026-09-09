{ config, pkgs, ... }:

{
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "26.05";

  home.file.".config/quickshell".source = ./config/quickshell;
  home.file.".config/kitty".source      = ./config/kitty;
  home.file.".config/hypr".source       = ./config/hypr;
  home.file.".config/nvim".source       = ./config/nvim;
  home.file.".config/yazi".source       = ./config/yazi;
  home.file.".config/fastfetch".source  = ./config/fastfetch;


  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    maple-mono.NF
    inter
    quickshell
    awww
    fuzzel
    nemo
    yazi
    neovim
    ripgrep
    nil
    grimblast
    libnotify
    nixpkgs-fmt
    fastfetch
    nodejs
    gcc
    file
    jq
  ];

  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor = {
      enable = true;
      size = 24;
    };
  };

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

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo I use NixOS btw";
      };
  };
}
