{ self, ... }:
{
  flake.modules.nixos.claude-code.home-manager.sharedModules = [ self.modules.homeManager.claude-code ];

  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    home.packages = [ pkgs.claude-code ];
    # the .desktop is Claude Code's own, written into ~/.local/share/applications by it
    xdg.mimeApps.defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
  };
}