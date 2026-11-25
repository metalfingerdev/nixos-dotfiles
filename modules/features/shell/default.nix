{ self, ... }:
{
  flake.modules.nixos.shell.home-manager.sharedModules = [ self.modules.homeManager.shell ];

  flake.modules.homeManager.shell = { pkgs, ... }: {
    programs.bash = {
      enable = true;
      # ignoreboth: no duplicate lines, and a command typed with a leading space is not saved
      historyControl = [ "ignoreboth" ];
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

    # per-project environments from a .envrc (VS Code's direnv extension needs it on PATH too)
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    programs.fzf.enable = true; # Ctrl-R history, Ctrl-T files, Alt-C directories
    programs.zoxide.enable = true; # `z` jumps to directories by frecency
    programs.bat.enable = true;

    # The toolbox the agents (and I) expect: `nix shell` still covers anything else
    home.packages = with pkgs; [
      ripgrep
      fd
      tree
      sqlite
      uv
      shellcheck
    ];
  };
}
