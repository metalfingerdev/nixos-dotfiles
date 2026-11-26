{ ... }:
{
  flake.modules.nixos.swap = {
    # Compressed swap in RAM (zram), up to half the RAM by default. With no swap at all, a big local build
    # (Open WebUI's frontend, since removed, reached ~7 GB) next to the desktop got OOM-killed. zram has
    # the higher priority, so everyday swapping stays in RAM and the swapfile below stays free for hibernation.
    zramSwap.enable = true;
    # 60 is tuned for swap on disk, where reading a page back is slow. From zram it's a decompression, so
    # the kernel docs suggest above 100 for swap in memory: idle pages go there before the file cache.
    boot.kernel.sysctl."vm.swappiness" = 180;

    # A swapfile on disk to hibernate into (`systemctl hibernate`). No resume= or resume_offset needed:
    # systemd stores the file's location in an EFI variable at hibernate time and the initrd reads it.
    # 8 GiB, not RAM-sized, because omen's / is small (raise it on a bigger disk); the image is
    # compressed, and systemd refuses to hibernate (it doesn't fail half-way) if more is in use than the
    # file can hold. Without this module there's nothing to hibernate into, and the island hides Hibernate.
    swapDevices = [ { device = "/var/lib/swapfile"; size = 8 * 1024; } ];

    # Closing the lid suspends; after an hour asleep it wakes and hibernates, so a forgotten laptop doesn't
    # drain its battery. If hibernating isn't possible then, logind just suspends.
    services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
    systemd.sleep.settings.Sleep.HibernateDelaySec = "1h";
  };
}
