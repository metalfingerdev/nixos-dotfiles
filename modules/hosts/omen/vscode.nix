{ ... }:
{
  # omen's VS Code, on top of the shared feature (features/vscode). Merged into the `omen` module.
  flake.modules.nixos.omen.home-manager.users.admin = { config, pkgs, ... }: {
    # Electron's GPU process opens every GPU it finds, and holding the offloaded GeForce kept it powered
    # on with nothing to draw (power/runtime_status "active"): its graphics libraries see only the
    # Radeon. Apps started from its terminal inherit this, so `nvidia-offload` there gets the Radeon.
    programs.vscode.package = pkgs.symlinkJoin {
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
    programs.vscode.profiles.default.extensions = [ pkgs.vscode-extensions.anthropic.claude-code ];
    # My settings, linked live to the config/vscode checkout so VS Code's own edits land there (and the
    # shared defaults are never seeded over it).
    xdg.configFile."Code/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.sessionVariables.NIXOS_FLAKE}/config/vscode/settings.json";
  };
}
