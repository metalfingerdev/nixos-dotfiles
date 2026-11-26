{ ... }:
{
  # Electron apps on the Radeon only. Their GPU process opens every GPU it finds, and holding the offloaded
  # GeForce kept it powered on with nothing to draw (power/runtime_status "active"): wrapped, their graphics
  # libraries see only the Radeon. Apps started from their terminals inherit this, so `nvidia-offload`
  # there gets the Radeon too. Their desktop entries start them by name, so the launcher gets the wrapper.
  flake.modules.nixos.omen.home-manager.users.admin = { pkgs, ... }:
    let
      radeonOnly = pkg: bin: pkgs.symlinkJoin {
        inherit (pkg) pname version;
        paths = [ pkg ];
        meta.mainProgram = bin;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/${bin} \
            --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json \
            --set __GLX_VENDOR_LIBRARY_NAME mesa \
            --set VK_DRIVER_FILES /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json
        '';
      };
    in
    {
      programs.vscode.package = radeonOnly pkgs.vscode-fhs "code";
      programs.antigravity.package = radeonOnly pkgs.antigravity-ide "antigravity-ide";
    };
}
