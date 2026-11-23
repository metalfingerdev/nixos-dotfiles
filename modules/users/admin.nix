{ ... }:
{
  flake.modules.nixos.admin = {
    users.users.admin = {
      isNormalUser = true;
      description = "admin";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    home-manager.users.admin = {
      home.stateVersion = "26.05";
      programs.git.settings.user = {
        name = "metalfingerdev";
        email = "prajwalpal@protonmail.com";
      };
    };
  };
}
