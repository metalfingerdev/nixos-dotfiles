{ inputs, self, ... }:
{
  flake.modules.nixos.yazi.home-manager.sharedModules = [ self.modules.homeManager.yazi ];

  flake.modules.homeManager.yazi = { pkgs, ... }: {
    home.file.".config/yazi".source = inputs.yazi;
    home.packages = [ pkgs.yazi ];
    xdg.mimeApps.defaultApplications."application/zip" = "yazi.desktop";
  };
}