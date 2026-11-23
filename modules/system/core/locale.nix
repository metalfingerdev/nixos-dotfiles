{ ... }:
{
  flake.modules.nixos.locale = {
    time.timeZone = "Asia/Kolkata";
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
