{ ... }:
{
  flake.modules.nixos.base = { pkgs, ... }: {
    time.timeZone = "Asia/Kolkata";

    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
      vim-full
      wget
    ];
  };
}