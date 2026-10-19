{ ... }:
{
  flake.modules.nixos.bluetooth = { ... }: {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General.FastConnectable = true;
        Policy.AutoEnable = true;
      };
    };

    # Realtek BT adapters stutter on A2DP when the USB link autosuspends.
    # Keep the btusb driver and the adapter itself awake.
    boot.extraModprobeConfig = ''
      options btusb enable_autosuspend=0
    '';

    services.udev.extraRules = ''
      # Bluetooth USB adapters (device class e0 = wireless controller): never runtime-suspend
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="e0", ATTR{power/control}="on"
    '';
  };
}