{ self, ... }:
{
  flake.modules.nixos.terminal.imports = with self.modules.nixos; [
    kitty
    shell
    yazi
    fastfetch
    utils
  ];
}
