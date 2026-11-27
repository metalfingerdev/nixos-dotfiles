{ self, ... }:
{
  # zathura, the default PDF viewer. LibreOffice stays offered for PDFs in "Open with" (features/libreoffice).
  flake.modules.nixos.zathura.home-manager.sharedModules = [ self.modules.homeManager.zathura ];

  flake.modules.homeManager.zathura = { pkgs, ... }: {
    home.packages = [ pkgs.zathura ];
    # zathura's PDF support is a plugin with its own launcher: this is the one whose MimeType has application/pdf
    xdg.mimeApps.defaultApplications."application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
  };
}
