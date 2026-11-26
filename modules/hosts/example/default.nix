{ inputs, self, ... }:
{
  # A template: the desktop, terminal, development tools and apps. No secure-boot (set it up later,
  # docs/secure-boot.md), no `agents` or `ai` bundle (personal, opt-in), no swap file.
  # Add your GPU driver from modules/drivers: `amdgpu`, and/or `nvidia` (a laptop with both also needs
  # PRIME bus IDs in example.nix: see modules/hosts/omen/omen.nix, ids from `lspci`).
  flake.nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.modules.nixos; [
      example
      changeme            # CHANGE: your user module (modules/users/<you>)
      desktop
      terminal
      development
      apps
      # amdgpu
      # nvidia
    ];
  };
}
