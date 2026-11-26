{ ... }:
{
  flake.modules.nixos.nix = {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # Hard-links identical files in the store, weekly, to save disk space. A timer rather than
    # auto-optimise-store, which slows every build down.
    nix.optimise.automatic = true;
  };
}
