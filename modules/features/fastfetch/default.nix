{ self, ... }:
{
  flake.modules.nixos.fastfetch.home-manager.sharedModules = [ self.modules.homeManager.fastfetch ];

  flake.modules.homeManager.fastfetch = { config, pkgs, ... }:
    let
      # Linked live from config/fastfetch (github.com/metalfingerdev/fastfetch), so edits apply without a rebuild.
      live = file: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/fastfetch/${file}";
    in
    {
      home.packages = [ pkgs.fastfetch ];
      xdg.configFile."fastfetch/config.jsonc".source = live "config.jsonc";
      xdg.configFile."fastfetch/logo.gif".source = live "logo.gif";
    };
}
