{ ... }:
{
  flake.modules.nixos.power = { ... }: {
    # power-saver / balanced / performance, switched from the island's Battery view and the
    # dashboard (powerprofilesctl). Conflicts with TLP and auto-cpufreq.
    services.power-profiles-daemon.enable = true;
  };
}
