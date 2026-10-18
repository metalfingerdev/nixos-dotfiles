{ ... }:
{
  flake.modules.homeManager.fastfetch = { config, ... }: {
    programs.fastfetch = {
      enable = true;
      settings.logo = {
        source = "${config.home.homeDirectory}/Pictures/marin-kitagawa.gif";
        type = "kitty-icat";
        width = 60;
        height = 20;
        padding = {
          top = 1;
          left = 0;
        };
      };
    };
  };
}