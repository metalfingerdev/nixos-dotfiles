{ self, ... }:
{
  flake.modules.nixos.libreoffice.home-manager.sharedModules = [ self.modules.homeManager.libreoffice ];

  flake.modules.homeManager.libreoffice = { pkgs, ... }: {
    home.packages = [ pkgs.libreoffice ];
  };
}
