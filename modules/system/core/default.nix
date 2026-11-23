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
      vim-full
      wget
    ];
  };
}
