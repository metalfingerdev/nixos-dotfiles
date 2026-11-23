{ self, ... }:
{
  flake.modules.nixos.fastfetch.home-manager.sharedModules = [ self.modules.homeManager.fastfetch ];

  flake.modules.homeManager.fastfetch = { config, pkgs, ... }:
    let
      # config/fastfetch is a local-only repo: linked live, so edits apply without a rebuild.
      live = file: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/fastfetch/${file}";
    in
    {
      home.packages = [ pkgs.fastfetch ];
      xdg.configFile."fastfetch/config.jsonc".source = live "config.jsonc";
      xdg.configFile."fastfetch/logo.gif".source = live "logo.gif";
    };
}
