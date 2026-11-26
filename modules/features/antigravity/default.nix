{ self, ... }:
{
  flake.modules.nixos.antigravity.home-manager.sharedModules = [ self.modules.homeManager.antigravity ];

  flake.modules.homeManager.antigravity = { pkgs, ... }:
    {
      programs.antigravity-cli = {
        enable = true;
        package = pkgs.antigravity-cli;
        mutableSettings = true;
      };

      programs.antigravity = {
        enable = true;
        package = pkgs.antigravity;
      };

      home.packages = [
        pkgs.antigravity-ide
      ];
    };
}
