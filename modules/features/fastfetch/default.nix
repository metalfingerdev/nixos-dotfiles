{ inputs, self, ... }:
{
  flake.modules.nixos.fastfetch.home-manager.sharedModules = [ self.modules.homeManager.fastfetch ];

  flake.modules.homeManager.fastfetch = { pkgs, ... }: {
    home.packages = [ pkgs.fastfetch ];
    # recursive: a link per file, so the config.jsonc link from before is replaced in place.
    xdg.configFile."fastfetch" = {
      source = inputs.fastfetch;
      recursive = true;
    };
  };
}
