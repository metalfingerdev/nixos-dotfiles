{ ... }:
{
  flake.modules.nixos.omen = {
    imports = [ ./_hardware.nix ];

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "omen";
    time.timeZone = "Asia/Kolkata";
    # VS Code's omen-only parts are in vscode.nix, beside this file.
    home-manager.users.admin = {
      # The laptop's own panel, loaded by hypr's monitors.lua (see its hyprland.lua). Outside
      # ~/.config/hypr, which is a read-only link to the hypr repo.
      # Caps Lock as Escape, read by hypr's input.lua; hl.config merges per key, so this is all it needs.
      xdg.configFile."hypr-host/input.lua".text = ''
        hl.config({ input = { kb_options = "caps:swapescape" } })
      '';
      xdg.configFile."hypr-host/monitors.lua".text = ''
        hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = "1" })
      '';
    };
    system.stateVersion = "26.05";

    # The EFI partition is 196 MB, shared with Windows 11's boot manager, and every kernel + initrd
    # takes ~45 MB of it. Lanzaboote writes a new one before deleting old ones, so keep the newest and
    # the running one. The running one counts toward the limit: at 1 it would push out every new build.
    boot.lanzaboote.configurationLimit = 2;

    # HP BIOS warning suppress
    boot.blacklistedKernelModules = [ "hp_bioscfg" ];

    # Hybrid graphics: the Radeon runs the desktop, and the GeForce stays powered off until an app is
    # started with `nvidia-offload`. Bus IDs from lspci (01:00.0 and 06:00.0, in decimal).
    hardware.nvidia.prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    hardware.nvidia.powerManagement.finegrained = true;

    # omen's Realtek Bluetooth stutters on A2DP when its USB link autosuspends: keep the btusb driver and
    # the adapter itself awake (device class e0 = wireless controller).
    boot.extraModprobeConfig = ''
      options btusb enable_autosuspend=0
    '';
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="e0", ATTR{power/control}="on"
    '';
  };
}
