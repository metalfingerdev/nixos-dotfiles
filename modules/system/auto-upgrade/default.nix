{ ... }:
{
  # In no host's list: both are rebuilt by hand.
  # Every night, build the latest push on GitHub; nixos-rebuild picks the host by its hostname.
  # The URL is my repo: a fork points it at its own.
  # "boot": the new version starts at the next reboot, and the previous one stays in the boot menu.
  flake.modules.nixos.auto-upgrade = {
    system.autoUpgrade = {
      enable = true;
      flake = "github:metalfingerdev/nixos-dotfiles";
      dates = "04:00";
      operation = "boot";
    };
  };
}
