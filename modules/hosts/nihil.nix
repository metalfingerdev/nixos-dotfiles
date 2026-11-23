{ inputs, self, ... }:
{
  # Attribute name must match host.name in settings.json: the nihil CLI rebuilds <flake>#<host.name>.
  flake.nixosConfigurations.nihil = inputs.nihil.lib.mkSystem {
    settings = builtins.fromJSON (builtins.readFile ../../settings.json);
    # Only omen's apps: its desktop modules (hyprland, quickshell, kitty, theme, ...) are what Nihil replaces.
    modules = (with self.modules.nixos; [
      secure-boot
      base
      git
      firefox
      steam
      nix-ld
      usb
      bittorrent
    ]) ++ [
      ../../hardware-configuration.nix
      ../../nihil/local.nix
      (let unstable = import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; in {
        # omen's Firefox exactly: an older Firefox refuses a profile a newer one last opened.
        programs.firefox.package = unstable.firefox;
        # Not packaged in Nihil's nixos-26.05.
        nixpkgs.overlays = [ (_: _: { inherit (unstable) stremio-service; }) ];
      })
    ];
    home = (with self.modules.homeManager; [
      git
      lazygit
      yazi
      utils
      audio
      bittorrent
      claude-code
      python3
      webdev
      luarocks
      vscode
      stremio
      vlc
      libreoffice
    ]) ++ [ ../../nihil/home.nix ];
  };
}
