{ self, ... }:
{
  flake.modules.nixos.claude-code.home-manager.sharedModules = [ self.modules.homeManager.claude-code ];

  flake.modules.homeManager.claude-code = { pkgs, ... }:
    let policy = import ../agent-policy/_policy.nix; in
    {
      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
        # Claude Code writes its own settings.json (model, plugins, theme): declared values are merged into the
        # real file at activation and everything else stays. Memory is not set here: memory.text/source would
        # take over ~/.claude/CLAUDE.md, which holds my own rules (see features/agent-memory instead).
        mutableSettings = true;
        settings.permissions.deny = policy.claudeDeny;
      };
      # the .desktop is Claude Code's own, written into ~/.local/share/applications by it
      xdg.mimeApps.defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
}
