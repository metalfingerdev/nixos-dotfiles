{ ... }:
{
  flake.modules.nixos.base = { pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
      vim-full
      wget
    ];
  };
}