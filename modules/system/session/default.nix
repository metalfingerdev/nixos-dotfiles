{ ... }:
{
  flake.modules.nixos.session = { ... }: {
    services.displayManager.ly.enable = true;
    security.pam.services.ly.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;

    services.libinput.enable = true;
    services.printing.enable = true;
  };
}