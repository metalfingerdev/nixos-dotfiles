{ inputs, self, ... }:
{
  # kitty, the terminal that hypr's binds and the island open; its config is the kitty repo (a flake
  # input, read-only in ~/.config/kitty).
  flake.modules.nixos.kitty = { pkgs, ... }: {
    home-manager.sharedModules = [ self.modules.homeManager.kitty ];
    environment.systemPackages = [ pkgs.kitty ];
  };

  flake.modules.homeManager.kitty = { ... }: {
    home.file.".config/kitty".source = inputs.kitty;
  };
}