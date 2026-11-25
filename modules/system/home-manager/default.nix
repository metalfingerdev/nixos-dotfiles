{ inputs, ... }:
{
  flake.modules.nixos.home-manager = { ... }: {
    # flake.modules sets no key, so without one a second import would load Home Manager's module twice.
    key = "modules.nixos.home-manager";
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      # mimeapps.list from the features' xdg.mimeApps.defaultApplications, not from whatever app set it last
      sharedModules = [ { xdg.mimeApps.enable = true; } ];
    };
  };
}
