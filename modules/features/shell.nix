{ self, ... }:
{
  flake.modules.nixos.shell.home-manager.sharedModules = [ self.modules.homeManager.shell ];

  flake.modules.homeManager.shell = { ... }: {
    programs.bash = {
      enable = true;
      # --flake without #name picks the configuration matching the hostname
      shellAliases = {
        btw = "echo I use NixOS btw";
        rebuild = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#omen";
        boot = "sudo nixos-rebuild boot --flake ~/nixos-dotfiles#omen";
        build = "nixos-rebuild build --flake ~/nixos-dotfiles#omen";
        daulat = "python ~/Projects/daulat/app.py";
      };
    };
  };
}