{ ... }:
{
  flake.modules.homeManager.git = { ... }: {
    programs.git = {
      enable = true;
      settings.user = {
        name = "mfdev";
        email = "prajwalpal@protonmail.com";
      };
    };
  };
}