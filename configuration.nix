{ config, pkgs, lib, ... }:
let
  sources = import ./lon.nix;
  lanzaboote = import sources.lanzaboote { inherit pkgs; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      lanzaboote.nixosModules.lanzaboote
    ];

  # HP bios warning suppress
  boot.blacklistedKernelModules = [ "hp_bioscfg" ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  networking.hostName = "omen"; # Define your hostname.
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";

  services.xserver.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  services.displayManager.ly.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  
  services.printing.enable = true;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.libinput.enable = true;
  services.blueman.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  users.users."admin" = {
    isNormalUser = true;
    description = "admin";
    extraGroups = [ "networkmanager" "wheel" ];
  };
  programs.firefox.enable = true;
  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };
  
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    kitty
  ];
  
  system.stateVersion = "26.05"; 
}
