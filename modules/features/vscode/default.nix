{ self, ... }:
{
  flake.modules.nixos.vscode.home-manager.sharedModules = [ self.modules.homeManager.vscode ];

  flake.modules.homeManager.vscode = { config, lib, pkgs, ... }:
    {
    # mkhl.direnv needs direnv on PATH. features/shell enables it too; mkDefault keeps this feature self-contained.
    programs.direnv = {
      enable = lib.mkDefault true;
      nix-direnv.enable = lib.mkDefault true;
    };

    # the Nix extension's language server and formatter (_settings.json names them)
    home.packages = [ pkgs.nil pkgs.nixpkgs-fmt ];

    # Default settings, copied once and then yours: a Home Manager-managed settings.json is a read-only
    # link, and VS Code's Settings UI fails to save into it. Skipped when a host links its own (omen).
    home.activation.vscodeSettings = lib.mkIf (!(config.xdg.configFile ? "Code/User/settings.json"))
      (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        f="${config.xdg.configHome}/Code/User/settings.json"
        [ -e "$f" ] || [ -L "$f" ] || run install -Dm644 ${./_settings.json} "$f"
      '');

    programs.vscode = {
      enable = true;
      package = lib.mkDefault pkgs.vscode-fhs; # the FHS build: marketplace extensions with binaries crash otherwise
      profiles.default.extensions = (with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        mkhl.direnv
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-python.vscode-python-envs
        svelte.svelte-vscode
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        bradlc.vscode-tailwindcss
        yoavbls.pretty-ts-errors
        christian-kohler.path-intellisense
      ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # Not packaged in nixpkgs
        {
          publisher = "theqtcompany";
          name = "qt-core";
          version = "1.16.0";
          hash = "sha256-6NBWsK7ljx7Ie3xvOrjBClyvwQP1UltCna1jQHJST5U=";
        }
        {
          publisher = "theqtcompany";
          name = "qt-qml";
          version = "1.16.0";
          hash = "sha256-QWjUSbBtHIdxYZyRBDn64HXhvSwhgzm7DjDaed6lNds=";
        }
        {
          publisher = "oven";
          name = "bun-vscode";
          version = "0.0.32";
          hash = "sha256-VlruOHiF5/wVhVVW1rq6DEc90u3IwbxD/tpTXyphD+U=";
        }
      ];
    };

  };
}
