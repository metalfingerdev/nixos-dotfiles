{ ... }:
{
  flake.modules.homeManager.shell = { ... }: {
    programs.ssh.enable = true;

    programs.bash = {
      enable = true;
      shellAliases = {
        btw = "echo I use NixOS btw";
      };
    };
  };
}