{ self, ... }:
{
  flake.modules.nixos.ssh = { config, lib, ... }: {
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

    home-manager.sharedModules = [ self.modules.homeManager.ssh ];
  };

  flake.modules.homeManager.ssh = { lib, ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github";
        IdentitiesOnly = true;
      };
    };

    # home-manager normally symlinks ~/.ssh/config into /nix/store, which
    # fails OpenSSH's strict ownership/permission check ("Bad owner or
    # permissions"). Replace the symlink with a real, 600-mode copy.
    home.activation.deSymlinkSshConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -L "$HOME/.ssh/config" ]; then
        $DRY_RUN_CMD install -m600 $VERBOSE_ARG \
          "$(readlink -f "$HOME/.ssh/config")" "$HOME/.ssh/config.tmp"
        $DRY_RUN_CMD mv $VERBOSE_ARG "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"
      fi
    '';
  };
}
