{ ... }:
{
  # What comes before and around Hyprland: ly, the text-mode login screen; GNOME Keyring, unlocked by
  # the login password, where apps keep secrets; polkit, for apps that ask for root; libinput for
  # touchpads; CUPS for printing.
  flake.modules.nixos.session = { ... }: {
    services.displayManager.ly.enable = true;
    security.pam.services.ly.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;

    services.libinput.enable = true;
    services.printing.enable = true;
  };
}