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
        # Delete every old generation, then rewrite the boot menu for the newest without rebuilding
        # (a rebuild would make whatever ~/nixos-dotfiles holds the default).
        clean = "sudo nix-collect-garbage -d && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot";
      };
    };
  };
}