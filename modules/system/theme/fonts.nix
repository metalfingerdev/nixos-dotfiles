{ self, ... }:
{
  # One font per kind, everywhere: Inter for sans, Source Serif 4 for serif, JetBrains Mono for mono. They
  # are fontconfig's defaults, so every app asking for "sans-serif", "serif" or "monospace" gets them (the
  # island, kitty and GTK name them too: system/theme/gtk.nix). Material Symbols are the island's icons:
  # glyphs of that font, so without it the island shows boxes.
  flake.modules.nixos.fonts.home-manager.sharedModules = [ self.modules.homeManager.fonts ];

  flake.modules.homeManager.fonts = { pkgs, ... }: {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Inter" ];
        serif = [ "Source Serif 4" ];
        monospace = [ "JetBrains Mono" ];
      };
    };
    home.packages = with pkgs; [
      jetbrains-mono
      inter
      source-serif
      material-symbols
    ];
  };
}
