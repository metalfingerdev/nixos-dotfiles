{ ... }:
{
  # Lets prebuilt dynamically-linked binaries (npm/pip native deps, downloaded CLIs) find a loader and libs.
  flake.modules.nixos.nix-ld = { pkgs, ... }: {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      openssl
      curl
      icu
    ];
  };
}
