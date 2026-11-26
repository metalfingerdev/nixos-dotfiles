{ self, ... }:
{
  flake.modules.nixos.shell.home-manager.sharedModules = [ self.modules.homeManager.shell ];

  flake.modules.homeManager.shell = { config, lib, pkgs, ... }:
    let
      # Baked in at build time, not read from $NIXOS_FLAKE at run time: hm-session-vars.sh exports a
      # guard, so a terminal in a session that sourced an older copy never sees a newly added variable.
      flake = lib.replaceStrings [ config.home.homeDirectory ] [ "~" ] config.home.sessionVariables.NIXOS_FLAKE;
    in {
    programs.bash = {
      enable = true;
      # ignoreboth: no duplicate lines, and a command typed with a leading space is not saved
      historyControl = [ "ignoreboth" ];
      # --flake without #name picks the configuration matching the hostname
      shellAliases = {
        btw = "echo I use NixOS btw";
        try = "sudo nixos-rebuild test --flake ${flake}";
        rebuild = "sudo nixos-rebuild switch --flake ${flake}";
        boot = "sudo nixos-rebuild boot --flake ${flake}";
        build = "nixos-rebuild build --flake ${flake}";
        # Delete every old generation, then rewrite the boot menu for the newest without rebuilding
        # (a rebuild would make whatever the flake checkout holds the default).
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

    # The command-line toolbox; `nix shell nixpkgs#<tool>` covers anything else
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
