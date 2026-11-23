{ ... }:
{
  flake.modules.nixos.home = {
    imports = [ ./_hardware.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "home";
    # The NixOS release this machine is first installed with; never change it afterwards.
    system.stateVersion = "26.05";
  };
}
