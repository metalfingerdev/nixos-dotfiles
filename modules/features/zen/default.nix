{ inputs, self, ... }:
{
  flake.modules.nixos.zen.home-manager.sharedModules = [ self.modules.homeManager.zen ];

  # Zen: Gecko, like Firefox, with vertical tabs, a compact mode and split view of its own. It sits
  # alongside Firefox (features/firefox), which stays the default browser. Vim keys come from Tridactyl.
  flake.modules.homeManager.zen = { pkgs, ... }: {
    imports = [ inputs.zen-browser.homeModules.beta ];

    programs.zen-browser = {
      enable = true;

      # Tridactyl's messenger: without it Tridactyl can't read its rc file below, nor open a text
      # field in Neovim (Ctrl+I).
      nativeMessagingHosts = [ pkgs.tridactyl-native ];

      # Browser policies (https://mozilla.github.io/policy-templates/). The extension is installed,
      # and kept, by its Mozilla ID, straight from addons.mozilla.org: no NUR needed.
      policies = {
        ExtensionSettings."tridactyl.vim@cmcaine.co.uk" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
          installation_mode = "force_installed";
        };
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DontCheckDefaultBrowser = true;   # Firefox is the default; Zen shouldn't ask
      };
    };

    xdg.configFile."tridactyl/tridactylrc".source = ./tridactylrc;
  };
}
