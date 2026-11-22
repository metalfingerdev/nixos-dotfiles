# Kept outside modules/ because import-tree loads every .nix there as a flake-parts module.
{ ... }:
{
  system.stateVersion = "26.05";
  nihil.flake = "/home/admin/nixos-dotfiles";

  # HP BIOS warning suppress, same as omen.
  boot.blacklistedKernelModules = [ "hp_bioscfg" ];
}
