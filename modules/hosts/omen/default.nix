{ inputs, self, ... }:
{
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      omen
      admin

      # system
      base
      home-manager
      ssh
      usb
      nix-ld
      session
      audio
      networking
      bluetooth
      power
      theme

      # features
      hyprland
      awww
      quickshell
      kitty
      shell
      yazi
      fastfetch
      utils
      git
      lazygit
      neovim
      vscode
      claude-code
      python3
      webdev
      firefox
      libreoffice
      vlc
      stremio
      bittorrent
    ];
  };
}
