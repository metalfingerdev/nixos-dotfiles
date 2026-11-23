{ inputs, self, ... }:
{
  # A gaming-only machine: the desktop and Steam, no dev tools or apps. No Secure Boot keys yet, so
  # it boots with plain systemd-boot (docs/secure-boot.md, "Setting it up from scratch"). Its GPU
  # driver (amdgpu or nvidia, from modules/drivers) goes in once the card is known.
  flake.nixosConfigurations.home = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      home
      desktop
      gaming
      kitty
      shell
      yazi
      utils
    ];
  };
}
