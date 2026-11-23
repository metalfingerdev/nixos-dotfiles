{ ... }:
{
  flake.modules.nixos.home = { lib, ... }: {
    imports = [ ./_hardware.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "home";
    # The NixOS release this machine is first installed with; never change it afterwards.
    system.stateVersion = "26.05";

    # No Secure Boot keys on this machine yet, so plain systemd-boot until they exist
    # (docs/secure-boot.md, "Setting it up from scratch").
    boot.lanzaboote.enable = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkOverride 40 true;
  };
}
