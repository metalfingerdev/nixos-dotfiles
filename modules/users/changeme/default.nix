{ ... }:
let
  # CHANGE: the account the NixOS installer made for you. A different name creates a new account with no
  # password, and you can't log into it. The module is named after it, so a host lists it by this name.
  user = "changeme";
in
{
  # A template person: copy this folder to modules/users/<you>/ (docs/new-machine.md), set `user` and your
  # git identity, and put <you> in your host's list in place of `changeme`. Things only one machine needs
  # (monitors, GPU) go in the host instead.
  flake.modules.nixos.${user} = { lib, ... }: {
    warnings = lib.optional (user == "changeme")
      "modules/users/changeme is the template user: copy it and set `user` to the account the installer made";

    users.users.${user} = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
    };
    home-manager.users.${user} = {
      # The NixOS release you first install with, like system.stateVersion: never change it afterwards.
      home.stateVersion = "26.05";
      # CHANGE: your git identity. Kept here, not in the shared git feature: it's per person.
      # programs.git.settings.user = { name = "Your Name"; email = "you@example.com"; };
      # Cloned somewhere other than ~/nixos-dotfiles:
      # home.sessionVariables.NIXOS_FLAKE = "/path/to/checkout";
    };
  };
}
