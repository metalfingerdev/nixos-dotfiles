{ lib, ... }:
{
  # Plasma-only theming that Nihil (Hyprland) never uses. Its generated script writes
  # `username=admin` unquoted, and shellcheck fails the build (SC2209: `admin` is a command name).
  stylix.targets.kde.enable = false;

  # From omen's admin module, which can't be imported: its fastfetch logo clashes with Nihil's.
  programs.git.settings.user = {
    name = "metalfingerdev";
    email = "prajwalpal@protonmail.com";
  };

  # omen links these folders whole into the read-only store, and Nihil puts its own files inside
  # them. Home Manager keeps such a link while the new generation still has files under it, then
  # fails writing into the store. Dropping omen's links first is safe: omen relinks them on boot.
  home.activation.unlinkOmenDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for dir in hypr kitty nvim quickshell; do
      target="$HOME/.config/$dir"
      if [[ -L $target && $(readlink "$target") == /nix/store/*-home-manager-files/* ]]; then
        run rm $VERBOSE_ARG "$target"
      fi
    done
  '';
}
