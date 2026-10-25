{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.omen ];
  };

  flake.modules.nixos.omen = {
    imports = (with self.modules.nixos; [
      base
      users
      desktop
      hyprland
      audio
      ssh
      networking
      bluetooth
      secure-boot
      home-manager
      git
      kitty
      firefox
    ]) ++ [ ../../hardware-configuration.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "omen";
    system.stateVersion = "26.05";

    # Omen-specific bug fix: HP bios warning suppress
    boot.blacklistedKernelModules = [ "hp_bioscfg" ];

    home-manager.users.admin = {
      imports = with self.modules.homeManager; [
        users
        hyprland
        quickshell
        awww
        audio
        kitty
        neovim
        yazi
        fastfetch
        utils
        theme
        git
        shell
        vscode
        claude-code
      ];

      home.stateVersion = "26.05";
    };
  };
}