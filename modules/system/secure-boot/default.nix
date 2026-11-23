{ inputs, self, ... }:
let
  # A generation alone in the boot menu is titled just "NixOS"; with more, each keeps lanzaboote's
  # full label and generation so they can be told apart.
  title = self.lib.optionalPatch {
    name = "lanzaboote's boot entry title";
    patch = ./lanzaboote-title.patch;
    file = "${inputs.lanzaboote}/rust/tool/systemd/src/install.rs";
  };
in
{
  # Secure Boot: lanzaboote signs each generation with the keys in /var/lib/sbctl (docs/secure-boot.md).
  flake.modules.nixos.secure-boot = { lib, pkgs, ... }: {
    # flake.modules sets no key, so without one a second import would load lanzaboote's module twice.
    key = "modules.nixos.secure-boot";
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    boot.loader.systemd-boot.enable = lib.mkForce false; # lanzaboote writes the boot menu itself
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = lib.mkDefault 10;
      package = lib.mkIf title.applies
        (inputs.lanzaboote.packages.${pkgs.stdenv.hostPlatform.system}.lzbt.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ title.patches;
          doCheck = false; # an integration test expects the old title
        }));
    };
    warnings = title.warnings;
    # Makes and enrolls the keys, and checks what lanzaboote signed (sbctl verify).
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
