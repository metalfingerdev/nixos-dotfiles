{ self, ... }:
{
  flake.modules.nixos.vscode.home-manager.sharedModules = [ self.modules.homeManager.vscode ];

  flake.modules.homeManager.vscode = { config, pkgs, ... }: {
    # vscode.nix-direnv integration needs direnv on PATH
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs; # Fixes marketplace extension binary crashes
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
        anthropic.claude-code
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

    # Settings are a plain file in config/vscode, linked live rather than copied into the store, so
    # changes made in VS Code are saved there and apply instantly, with no rebuild.
    xdg.configFile."Code/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/vscode/settings.json";
  };
}
