{ inputs, self, ... }:
{
  # Attribute name must match host.name in settings.json: the nihil CLI rebuilds <flake>#<host.name>.
  flake.nixosConfigurations.omen-nihil = inputs.nihil.lib.mkSystem {
    settings = builtins.fromJSON (builtins.readFile ../../settings.json);
    modules = [
      ../../hardware-configuration.nix
      self.modules.nixos.secure-boot
      ../../nihil/local.nix
    ];
    home = [ ../../nihil/home.nix ];
  };
}
