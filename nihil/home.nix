{ ... }:
{
  # Plasma-only theming that Nihil (Hyprland) never uses. Its generated script writes
  # `username=admin` unquoted, and shellcheck fails the build (SC2209: `admin` is a command name).
  stylix.targets.kde.enable = false;
}
