{ pkgs, ... }:
{
  home.packages = with pkgs; [
    maple-mono.NF
    inter
    quickshell
    pavucontrol
    pulsemixer
    usbutils
    material-symbols
    awww
    nemo
    yazi
    neovim
    ripgrep
    nil
    grimblast
    libnotify
    nixpkgs-fmt
    brightnessctl
    fastfetch
    nodejs
    gcc
    file
    jq
    papirus-icon-theme
  ];
}