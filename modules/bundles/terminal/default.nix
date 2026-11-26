{ self, ... }:
{
  # The terminal and what runs in it.
  flake.modules.nixos.terminal.imports = with self.modules.nixos; [
    kitty
    shell
    yazi
    fastfetch
    utils
  ];
}
