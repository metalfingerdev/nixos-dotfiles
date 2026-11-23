{ self, ... }:
{
  flake.modules.nixos.calibre.home-manager.sharedModules = [ self.modules.homeManager.calibre ];

  # Converts EPUB to AZW3 and sends books to a Kindle.
  flake.modules.homeManager.calibre = { pkgs, ... }: {
    home.packages = [ pkgs.calibre ];
  };
}
