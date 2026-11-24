{ self, ... }:
{
  flake.modules.nixos.core = { pkgs, ... }: {
    imports = with self.modules.nixos; [
      user
      bootloader
      nix
      locale
      home-manager
      ssh
      nix-ld
    ];

    environment.systemPackages = with pkgs; [
      vim                 # not vim-full: that's GUI vim and every language binding (553 MiB), next to neovim
      wget
      git
    ];
  };
}
