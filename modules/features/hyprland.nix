{ ... }:
{
  flake.modules.nixos.hyprland = { ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  flake.modules.homeManager.hyprland = { pkgs, ... }: {
    home.file.".config/hypr".source = ../../config/hypr;
    home.file.".config/quickshell".source = ../../config/quickshell;

    home.packages = with pkgs; [
      quickshell
      awww
      grimblast
      libnotify
      brightnessctl
    ];
  };
}