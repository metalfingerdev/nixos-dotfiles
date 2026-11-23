{ self, ... }:
{
  # The marin theme, everything that sets the look across apps.
  flake.modules.nixos.theme.imports = with self.modules.nixos; [
    cursor
    gtk
    fonts
    marin
  ];
}
