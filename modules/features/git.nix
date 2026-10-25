{ ... }:
{
  flake.modules.nixos.git = { ... }: {
    programs.git = {
      enable = true;
      config.user = {
        name = "mfdev";
        email = "prajwalpal@protonmail.com";
      };
    };
  };
}
