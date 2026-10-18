{ ... }:
{
  flake.modules.nixos.users = { ... }: {
    users.users."admin" = {
      isNormalUser = true;
      description = "admin";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
      ];
    };
  };
}