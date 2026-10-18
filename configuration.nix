{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/desktop.nix
    ./modules/audio.nix
    ./modules/bluetooth.nix
  ];

  networking.hostName = "omen";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Kolkata";

  users.users."admin" = {
    isNormalUser = true;
    description = "admin";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    vim-full
    wget
    git
    kitty
  ];

  system.stateVersion = "26.05";
}