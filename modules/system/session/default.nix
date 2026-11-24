{ ... }:
{
  flake.modules.nixos.session = { ... }: {
    services.displayManager.ly.enable = true;
    security.pam.services.ly.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;

    services.libinput.enable = true;
    services.printing.enable = true;
    # NixOS turns on speech synthesis for every desktop, and its voices are 645 MB. Nothing here reads
    # aloud (it's Firefox's Read Aloud and screen readers).
    services.speechd.enable = false;
  };
}