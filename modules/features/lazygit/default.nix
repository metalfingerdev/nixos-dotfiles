{ self, ... }:
{
  # lazygit, a terminal UI for git.
  flake.modules.nixos.lazygit.home-manager.sharedModules = [ self.modules.homeManager.lazygit ];

  flake.modules.homeManager.lazygit = { ... }: {
    programs.lazygit.enable = true;
  };
}
