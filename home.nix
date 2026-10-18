{ ... }:
{
  imports = [
    ./home/dotfiles.nix
    ./home/packages.nix
    ./home/theme.nix
    ./home/programs.nix
  ];

  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "26.05";
}