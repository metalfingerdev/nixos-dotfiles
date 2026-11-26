{ self, ... }:
{
  # What every machine needs, desktop or not. A machine's people come from modules/users/, its hardware
  # from its host.
  flake.modules.nixos.core = { pkgs, ... }: {
    imports = with self.modules.nixos; [
      bootloader
      nix
      home-manager
      nix-ld
      etc-nixos
    ];

    environment.systemPackages = with pkgs; [
      vim                 # not vim-full: that's GUI vim and every language binding (553 MiB), next to neovim
      wget
      git
    ];
  };
}
