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
        # Drop old generations, then rewrite the boot menu for the newest one. Rebuilding instead would
        # make ~/nixos-dotfiles the default, which on home is the stale copy from install.
        clean = "sudo nix-collect-garbage --delete-older-than 14d && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot";
      };
    };
  };
}