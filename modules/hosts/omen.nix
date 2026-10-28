{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.omen ];
  };

  flake.modules.nixos.omen = {
    imports = (with self.modules.nixos; [
      base
      admin
      desktop
      hyprland
      audio
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
    time.timeZone = "Asia/Kolkata";
    system.stateVersion = "26.05";

    # Omen-specific bug fix: HP bios warning suppress
    boot.blacklistedKernelModules = [ "hp_bioscfg" ];

    home-manager.users.admin = {
      imports = with self.modules.homeManager; [
        admin
        git
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
        shell
        vscode
        claude-code
        python3
        webdev
        stremio
      ];

      home.stateVersion = "26.05";
    };
  };
}