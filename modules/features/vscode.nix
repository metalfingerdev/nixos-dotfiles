{ ... }:
{
  flake.modules.homeManager.vscode = { pkgs, ... }: {
    # vscode.nix-direnv integration needs direnv on PATH
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs; # Fixes marketplace extension binary crashes
      profiles.default = {
        extensions = (with pkgs.vscode-extensions; [
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

        userSettings = {
          "editor.minimap.enabled" = false;
          "workbench.startupEditor" = "none";
          "terminal.integrated.initialHint" = false;
          "git.autofetch" = true;

          # Copilot ghost text / inline suggestions
          "github.completions.enabled" = true;
          "github.copilot.inlineSuggest.enable" = true;

          "workbench.editorAssociations" = {
            "*.copilotmd" = "vscode.markdown.preview.editor";
            "{git,gitlens,chat-editing-snapshot-text-model,copilot,git-graph,git-graph-3}:/**/*.qrc" = "default";
            "*.qrc" = "qt-core.qrcEditor";
          };
          "qt-core.showWelcomePageOnActivation" = false;

          "chat.viewSessions.orientation" = "stacked";

          "claudeCode.preferredLocation" = "panel";
          "claudeCode.hideOnboarding" = true;
          "claudeCode.useTerminal" = true;

          # Web: Prettier formats, ESLint lints, TS uses the workspace version when present
          "[javascript][javascriptreact][typescript][typescriptreact][json][jsonc][html][css][scss][markdown]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[svelte]" = {
            "editor.defaultFormatter" = "svelte.svelte-vscode";
            "editor.formatOnSave" = true;
          };
          "eslint.useFlatConfig" = true;
          "npm.packageManager" = "pnpm";

          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";
          "nix.serverSettings".nil.formatting.command = [ "nixpkgs-fmt" ];
        };
      };
    };
  };
}
