{ self, ... }:
{
  # JetBrains Mono for the terminal (kitty.conf), Inter and Material Symbols for the island: its icons
  # are glyphs of that font, so without it the island shows boxes.
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
