{ self, ... }:
{
  flake.modules.nixos.fonts.home-manager.sharedModules = [ self.modules.homeManager.fonts ];

  flake.modules.homeManager.fonts = { pkgs, ... }: {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      jetbrains-mono
      inter
      material-symbols
    ];
  };
}
