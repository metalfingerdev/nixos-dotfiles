{ self, ... }:
{
  # qimgv, the default viewer for every common image format.
  flake.modules.nixos.qimgv.home-manager.sharedModules = [ self.modules.homeManager.qimgv ];

  flake.modules.homeManager.qimgv = { pkgs, ... }: {
    home.packages = [ pkgs.qimgv ];
    xdg.mimeApps.defaultApplications = pkgs.lib.genAttrs
      (map (t: "image/" + t) [ "jpeg" "png" "gif" "webp" "bmp" "tiff" "avif" "heic" "jxl" "svg+xml" "x-icon" ])
      (_: "qimgv.desktop");
  };
}
