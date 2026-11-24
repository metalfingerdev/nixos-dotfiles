{ self, ... }:
{
  # /etc/nixos: a read-only copy of this flake as it was when the running system was built, replaced on
  # every rebuild (older copies stay with their generations until garbage collection). Only Git-tracked
  # files are in it, so not config/ (those repos are pinned inputs) and nothing untracked.
  # It also means a bare `nixos-rebuild switch` rebuilds what is already running, never the installer's
  # old config. Edit ~/nixos-dotfiles, not this.
  flake.modules.nixos.etc-nixos = {
    environment.etc."nixos".source = self.outPath;
  };
}
