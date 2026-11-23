{ ... }:
{
  flake.modules.nixos.nix = {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # Every rebuild adds a generation, and the store keeps each one's packages until it's deleted.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
