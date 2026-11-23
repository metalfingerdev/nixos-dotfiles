{ inputs, self, ... }:
{
  flake.modules.nixos.kitty = { pkgs, ... }: {
    home-manager.sharedModules = [ self.modules.homeManager.kitty ];
    environment.systemPackages = [ pkgs.kitty ];
  };

  flake.modules.homeManager.kitty = { ... }: {
    home.file.".config/kitty".source = inputs.kitty;
  };
}