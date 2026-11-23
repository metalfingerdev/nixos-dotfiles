{ self, ... }:
{
  flake.modules.nixos.shell.home-manager.sharedModules = [ self.modules.homeManager.shell ];

  flake.modules.homeManager.shell = { ... }: {
    programs.bash = {
      enable = true;
      # --flake without #name picks the configuration matching the hostname
      shellAliases = {
        btw = "echo I use NixOS btw";
        try = "sudo nixos-rebuild test --flake ~/nixos-dotfiles";
        rebuild = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
        boot = "sudo nixos-rebuild boot --flake ~/nixos-dotfiles";
        build = "nixos-rebuild build --flake ~/nixos-dotfiles";
        # nixos-rebuild has no clean action: drop old generations, then rewrite the boot menu without them
        clean = "sudo nix-collect-garbage --delete-older-than 14d && sudo nixos-rebuild boot --flake ~/nixos-dotfiles";
      };
    };
  };
}