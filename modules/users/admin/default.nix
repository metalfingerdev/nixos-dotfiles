{ self, ... }:
{
  # My account and git identity, for my machines only (omen, home). Kept apart from the shared git
  # feature: identity is per person. Someone new copies modules/users/changeme.
  flake.modules.nixos.admin = {
    # ~/.ssh/config for GitHub with my key (~/.ssh/id_ed25519_github): mine, not every machine's.
    imports = [ self.modules.nixos.ssh ];
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
      # GitHub over SSH, with that key, even for https:// remotes
      programs.git.settings.url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
}
