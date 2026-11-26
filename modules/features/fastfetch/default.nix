{ self, ... }:
{
  flake.modules.nixos.fastfetch.home-manager.sharedModules = [ self.modules.homeManager.fastfetch ];
  flake.modules.homeManager.fastfetch = { lib, ... }: {
    programs.fastfetch = {
      enable = true;
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "kitty-icat";
          # From the store (assets/README.md), so it works wherever the repo is checked out.
          # Override in a host: programs.fastfetch.settings.logo.source = "/path/to/logo.png";
          # (a plain string is not copied into the store, so it can be a live file).
          source = lib.mkDefault "${../../../assets/fastfetch/logo.gif}";
          width = 60;
          height = 20;
          padding = { top = 1; left = 0; };
        };
        modules = [
          "title" "separator" "os" "host" "kernel" "uptime" "packages" "shell" "display" "de" "wm"
          "wmtheme" "theme" "icons" "font" "cursor" "terminal" "terminalfont" "cpu" "gpu" "memory"
          "swap" "disk" "localip" "battery" "poweradapter" "locale" "break" "colors"
        ];
      };
    };
  };
}
