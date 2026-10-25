{ ... }:
{
  flake.modules.homeManager.shell = { ... }: {
    programs.bash = {
      enable = true;
      # --flake without #name picks the configuration matching the hostname
      shellAliases = {
        btw = "echo I use NixOS btw";
        rebuild = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
        boot = "sudo nixos-rebuild boot --flake ~/nixos-dotfiles";
        build = "nixos-rebuild build --flake ~/nixos-dotfiles";
      };
    };
  };
}