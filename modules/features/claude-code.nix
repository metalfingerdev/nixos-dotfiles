{ ... }:
{
  flake.modules.homeManager.claude-code = { pks, ... }: {
    home.packages = [ pkgs.claude-code ];
  };
}