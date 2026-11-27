{ self, ... }:
{
  # The marin theme: cursor, GTK, Qt and fonts. The rest of the look is in the config repos, and the
  # island's pictures in the quickshell repo (fastfetch's logo is in assets/ here).
  flake.modules.nixos.theme.imports = with self.modules.nixos; [
    cursor
    gtk
    qt
    fonts
  ];
}
