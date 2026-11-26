{ inputs, self, ... }:
{
  # omen, my HP Omen laptop: a Radeon iGPU runs the desktop, a GTX 1650 is offloaded to (omen.nix).
  # Its own module is split over omen.nix (hardware, boot) and vscode.nix; they merge into `omen`.
  flake.nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      omen
      admin               # me: account and git identity
      secure-boot
      amdgpu # Radeon Vega (Cezanne) iGPU
      nvidia # GeForce GTX 1650 Mobile
      swap
      desktop
      terminal
      development
      apps
      editing
      ai
      claude-code # the coding agent: mine, so not in the shared development bundle
    ];
  };
}
