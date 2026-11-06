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
      # A config file without `modules` prints the logo and nothing else (fastfetch only falls
      # back to its default modules when there is no config file at all), so list them.
      settings.modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "display"
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "font"
        "cursor"
        "terminal"
        "terminalfont"
        "cpu"
        "gpu"
        "memory"
        "swap"
        "disk"
        "localip"
        "battery"
        "poweradapter"
        "locale"
        "break"
        "colors"
      ];
    };
  };
}
