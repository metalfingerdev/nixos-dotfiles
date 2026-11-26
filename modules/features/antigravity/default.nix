{ self, ... }:
{
  flake.modules.nixos.antigravity.home-manager.sharedModules = [ self.modules.homeManager.antigravity ];

  # Google's Antigravity: the agent-first editor (a VS Code fork) and its CLI. Unfree, which core allows.
  # In the `ai` bundle, with claude-code.
  flake.modules.homeManager.antigravity = { pkgs, ... }: {
    # The editor. `pkgs.antigravity` is an old name for this package.
    programs.antigravity = {
      enable = true;
      package = pkgs.antigravity-ide;
    };
    # The CLI writes its own settings (model, sign-in); declared ones are merged in, the rest stays.
    programs.antigravity-cli = {
      enable = true;
      mutableSettings = true;
    };
  };
}
