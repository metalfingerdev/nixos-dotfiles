{ ... }:
{
  flake.modules.nixos.nix = {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # Hard-links identical files in the store, weekly: / is short on room. A timer rather than
    # auto-optimise-store, which slows every build down.
    nix.optimise.automatic = true;
  };
}
