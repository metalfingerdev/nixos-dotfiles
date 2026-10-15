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
    
    # Modern NixOS configures WirePlumber explicitly through this sub-module
    wireplumber = {
      enable = true;
      extraConfig = {
        # 1. Override the bluetooth policy settings directly
        "11-bluetooth-policy" = {
          "wireplumber.settings" = {
            # Explicitly prevent WirePlumber from force-switching your profile 
            # down to a low-quality headset (HSP/HFP) profile when an app asks for a mic
            "bluetooth.autoswitch-to-headset-profile" = false;
          };
        };

        # 2. Configure BlueZ device management properties and power rules
        "10-bluez" = {
          "monitor.bluez.properties" = {
            # Strictly use high-quality profiles for audio streaming and recording
            "bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];
            "bluez5.auto-connect" = [ "a2dp_sink" ];
            "bluez5.experimental-features" = [ "battery-provider" ];
          };
          
          "monitor.bluez.rules" = [
            {
              matches = [
                { "node.name" = "~bluez_output.*"; }
              ];
              actions = {
                update-props = {
                  # Disable power-saving states that cause audio pops or delay when resuming streams
                  "session.suspend-timeout-seconds" = 0;
                  "node.pause-on-idle" = false;
                  "node.suspend-on-idle" = false;
                };
              };
            }
          ];
        };
      };
    };
  };

  # XDG Portals for PipeWire screen sharing on Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk 
      pkgs.xdg-desktop-portal-hyprland
    ];
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
