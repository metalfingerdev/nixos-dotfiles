{ self, ... }:
{
  # The marin theme: cursor, GTK and fonts. The rest of the look lives in the config repos.
  flake.modules.nixos.theme.imports = with self.modules.nixos; [
    cursor
    gtk
    fonts
  ];
}
