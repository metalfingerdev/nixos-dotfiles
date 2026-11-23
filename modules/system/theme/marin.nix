{ self, ... }:
{
  flake.modules.nixos.marin.home-manager.sharedModules = [ self.modules.homeManager.marin ];

  # Marin Kitagawa. Impure (outside the repo) until the gif is moved in.
  flake.modules.homeManager.marin = { config, ... }: {
    programs.fastfetch.settings.logo.source = "${config.home.homeDirectory}/Pictures/marin-kitagawa.gif";
  };
}
