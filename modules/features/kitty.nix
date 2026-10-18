{ ... }:
{
  flake.modules.homeManager.kitty = { ... }: {
    home.file.".config/kitty".source = ../../config/kitty;
  };
}