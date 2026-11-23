{ self, ... }:
{
  flake.modules.nixos.claude-code.home-manager.sharedModules = [ self.modules.homeManager.claude-code ];

  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    home.packages = [ pkgs.claude-code ];
  };
}