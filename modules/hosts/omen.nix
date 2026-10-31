{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.modules.nixos.omen ];
  };

  
    flake.modules.nixos.omen.imports = (with self.modules.nixos; [
      base
      admin
      desktop
      hyprland
      audio
      networking
      bluetooth
      power
      secure-boot
      home-manager
      git
      webdev
      kitty
      firefox
      bittorrent
    ]) ++ [ ../../hardware-configuration.nix ];

    flake.modules.nixos.omen.nixpkgs.hostPlatform = "x86_64-linux";
    flake.modules.nixos.omen.networking.hostName = "omen";
    flake.modules.nixos.omen.time.timeZone = "Asia/Kolkata";
    flake.modules.nixos.omen.system.stateVersion = "26.05";

    # Omen-specific bug fix: HP bios warning suppress
    flake.modules.nixos.omen.boot.blacklistedKernelModules = [ "hp_bioscfg" ];

    flake.modules.nixos.omen.home-manager.users.admin = {
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
        bittorrent
      ];

      home.stateVersion = "26.05";
    };
}
