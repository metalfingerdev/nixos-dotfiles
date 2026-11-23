{ self, ... }:
{
  flake.modules.nixos.audio = { ... }: {
    home-manager.sharedModules = [ self.modules.homeManager.audio ];
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };

  flake.modules.homeManager.audio = { pkgs, ... }: {
    home.packages = with pkgs; [
      pavucontrol
      pulsemixer
    ];
  };
}