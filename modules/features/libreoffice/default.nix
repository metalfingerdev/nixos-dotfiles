{ self, ... }:
{
  # LibreOffice. PDFs get Draw and Writer offered in "Open with", without taking over as their default.
  flake.modules.nixos.libreoffice.home-manager.sharedModules = [ self.modules.homeManager.libreoffice ];

  flake.modules.homeManager.libreoffice = { pkgs, ... }: {
    home.packages = [ pkgs.libreoffice ];
    xdg.mimeApps.associations.added."application/pdf" = [ "draw.desktop" "writer.desktop" ];
  };
}
