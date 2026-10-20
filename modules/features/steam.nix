{ ... }:
{
  flake.modules.homeManager.steam = { ... }: {
    programs.steam = {
      enable = true;
    };
  };
}