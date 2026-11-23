{ ... }:
{
  flake.modules.nixos.swap = {
    # Compressed swap in RAM (zram), up to half the RAM by default. With no swap at all, a big local build
    # (Open WebUI's frontend reaches ~7 GB) next to the desktop got OOM-killed. zram has the higher
    # priority, so everyday swapping stays in RAM and the swapfile below stays free for hibernation.
    zramSwap.enable = true;

    # A swapfile on disk to hibernate into (`systemctl hibernate`). No resume= or resume_offset needed:
    # systemd stores the file's location in an EFI variable at hibernate time and the initrd reads it.
    # 8 GiB, not RAM-sized, because / has little room; the image is compressed, and systemd refuses
    # to hibernate (it doesn't fail half-way) if more is in use than the file can hold.
    swapDevices = [ { device = "/var/lib/swapfile"; size = 8 * 1024; } ];

    # Closing the lid suspends; after an hour asleep it wakes and hibernates, so a forgotten laptop doesn't
    # drain its battery. If hibernating isn't possible then, logind just suspends.
    services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
    systemd.sleep.settings.Sleep.HibernateDelaySec = "1h";
  };
}
