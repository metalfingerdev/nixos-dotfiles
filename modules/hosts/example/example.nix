{ ... }:
{
  # Template for a new machine: copy this folder (docs/new-machine.md), rename `example` in all three
  # files, and fill in the values marked CHANGE. The person (account, git identity) is a module of its
  # own in modules/users/, listed in default.nix.
  flake.modules.nixos.example = {
    imports = [ ./_hardware.nix ];
    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "example"; # CHANGE
    # The NixOS release you first install with; never change it afterwards.
    system.stateVersion = "26.05";

    time.timeZone = "UTC"; # CHANGE: e.g. "Europe/Berlin"
    # Dual-booting Windows: it keeps the hardware clock in local time, so each OS shifts the other's.
    # time.hardwareClockInLocalTime = true;

    # This machine's monitors and keyboard, for whoever logs in, as Hyprland Lua that hypr's monitors.lua
    # and input.lua load (the hypr repo's hyprland.lua explains). Without them Hyprland picks
    # each screen's preferred mode and a US layout.
    # home-manager.sharedModules = [ {
    #   xdg.configFile."hypr-host/monitors.lua".text = ''hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = "1" })'';
    #   xdg.configFile."hypr-host/input.lua".text = ''hl.config({ input = { kb_layout = "de", kb_options = "caps:swapescape" } })'';
    # } ];

    # Windows' EFI partition is typically 100 MB and each generation takes ~45 MB of kernel and initrd
    # there, so keep few. With a separate /boot (XBOOTLDR, docs/dual-boot.md) raise or remove this, and set
    # boot.loader.efi.efiSysMountPoint = "/efi"; boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
    boot.loader.systemd-boot.configurationLimit = 3;
  };
}
