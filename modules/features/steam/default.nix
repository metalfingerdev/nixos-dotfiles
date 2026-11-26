{ ... }:
{
  # Steam, with the 32-bit graphics libraries and runtime its games need (programs.steam sets those up).
  flake.modules.nixos.steam = { ... }: {
    programs.steam.enable = true;
  };
}