{ ... }:
{
  # Bluetooth, on at boot, paired with Blueman or the island's Bluetooth view. FastConnectable: known
  # devices reconnect faster, for a little more power.
  flake.modules.nixos.bluetooth = { ... }: {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.FastConnectable = true;
    };
  };
}