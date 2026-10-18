{ ... }:
{
  # server: system-wide sshd
  flake.modules.nixos.ssh = { ... }: {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "admin" ];
        MaxAuthTries = 3;
        PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
      };
    };
  };

  # client: ~/.ssh/config
  flake.modules.homeManager.ssh = { ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
  };
}