{ ... }:
{
  flake.modules.nixos.admin = { ... }: {
    users.users.admin = {
      isNormalUser = true;
      description = "admin";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
      ];
    };
  };

  # home.username / home.homeDirectory are set by the home-manager NixOS module
  flake.modules.homeManager.admin = { config, ... }: {
    programs.git.settings.user = {
      name = "mfdev";
      email = "prajwalpal@protonmail.com";
    };

    programs.fastfetch.settings.logo.source =
      "${config.home.homeDirectory}/Pictures/marin-kitagawa.gif";
  };
}
