{ ... }:
{
  flake.modules.nixos.session = { ... }: {
    services.gvfs.enable = true;
    services.xserver.enable = true;

    services.displayManager.ly.enable = true;
    security.pam.services.ly.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;

    services.libinput.enable = true;
    services.printing.enable = true;
  };
}