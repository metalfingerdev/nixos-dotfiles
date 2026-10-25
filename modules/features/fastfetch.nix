{ ... }:
{
  flake.modules.homeManager.fastfetch = { ... }: {
    programs.fastfetch = {
      enable = true;
      # logo.source is set per user
      settings.logo = {
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