{ self, ... }:
{
  flake.modules.nixos.ssh.home-manager.sharedModules = [ self.modules.homeManager.ssh ];

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
        run install -m600 "$(readlink -f "$HOME/.ssh/config")" "$HOME/.ssh/config.tmp"
        run mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"
      fi
    '';
    # Otherwise a changed config moves that copy to config.backup, and the change after that fails
    # because the backup already exists.
    home.activation.dropSshConfigCopy = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      [ -L "$HOME/.ssh/config" ] || run rm -f "$HOME/.ssh/config"
    '';
  };
}
