{ ... }:
{
  flake.modules.nixos.kitty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kitty ];
  };

  flake.modules.homeManager.kitty = { ... }: {
    home.file.".config/kitty".source = ../../config/kitty;
  };
}