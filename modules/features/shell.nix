{ ... }:
{
  flake.modules.homeManager.shell = { ... }: {
    programs.bash = {
      enable = true;
      shellAliases = {
        btw = "echo I use NixOS btw";
        rebuild = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen";
        boot = "sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen";
        build = "nixos-rebuild build --flake ~/nixos-dotfiles#omen";
      };
    };
  };
}