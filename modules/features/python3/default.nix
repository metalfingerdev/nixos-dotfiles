{ self, ... }:
{
  # Python 3 with pandas and numpy. Projects with their own dependencies use uv (features/shell).
  flake.modules.nixos.python3.home-manager.sharedModules = [ self.modules.homeManager.python3 ];

  flake.modules.homeManager.python3 = { pkgs, ... }: {
    home.packages = [
      (pkgs.python3.withPackages (ps: with ps; [
        pandas
        numpy
      ]))
    ];
  };
}