{ ... }:
{
  # What comes before and around Hyprland: ly, the text-mode login screen; GNOME Keyring, unlocked by
  # the login password, where apps keep secrets; polkit, for apps that ask for root; libinput for
  # touchpads; CUPS for printing.
  flake.modules.nixos.session = { ... }: {
    services.displayManager.ly.enable = true;
    security.pam.services.ly.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
    # Chromium and every Electron app (VS Code, Antigravity, Discord, Obsidian...) choose a keyring by the
    # desktop they recognise; they don't know Hyprland, so they warn and fall back to weak encryption.
    # Naming GNOME too, after Hyprland, makes them use GNOME Keyring above. UWSM sources this file when
    # the session starts (after its own Hyprland plugin); portals still go by the first name, Hyprland.
    # Qt apps see GNOME and follow GTK's settings too (system/theme/gtk.nix); the island keeps Hyprland
    # (features/quickshell) and so its look.
    environment.etc."xdg/uwsm/env-hyprland".text = ''
      case ":$XDG_CURRENT_DESKTOP:" in
        *:GNOME:*) ;;
        *) export XDG_CURRENT_DESKTOP="$XDG_CURRENT_DESKTOP:GNOME" ;;
      esac
    '';
    security.polkit.enable = true;

    services.libinput.enable = true;
    services.printing.enable = true;
  };
}