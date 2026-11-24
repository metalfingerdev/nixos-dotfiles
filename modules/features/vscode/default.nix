{ self, ... }:
{
  flake.modules.nixos.vscode.home-manager.sharedModules = [ self.modules.homeManager.vscode ];

  flake.modules.homeManager.vscode = { config, pkgs, ... }:
    let
      # Electron's GPU process opens every GPU it finds, and holding the GeForce kept it powered on
      # with nothing to draw (power/runtime_status "active"): its graphics libraries see only the
      # Radeon. Apps started from its terminal inherit this, so `nvidia-offload` there gets the Radeon.
      vscode = pkgs.symlinkJoin {
        inherit (pkgs.vscode-fhs) pname version;
        paths = [ pkgs.vscode-fhs ];
        meta.mainProgram = "code";
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/code \
            --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json \
            --set __GLX_VENDOR_LIBRARY_NAME mesa \
            --set VK_DRIVER_FILES /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json
        '';
      };
    in
    {
    # vscode.nix-direnv integration needs direnv on PATH
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.vscode = {
      enable = true;
      package = vscode; # vscode-fhs: fixes marketplace extension binary crashes
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
