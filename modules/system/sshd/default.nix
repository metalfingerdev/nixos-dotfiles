{ ... }:
{
  # The SSH server, in no host's list: nothing logs in to these machines remotely.
  flake.modules.nixos.sshd = { config, lib, ... }: {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
        MaxAuthTries = 3;
        PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
      };
    };
  };
}
