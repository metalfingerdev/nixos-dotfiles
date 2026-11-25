{ self, ... }:
{
  flake.modules.nixos.agent-memory.home-manager.sharedModules = [ self.modules.homeManager.agent-memory ];

  # One memory file for both coding agents, owned by the person: created from a template only when it
  # doesn't exist, so edits are never overwritten. Crush reads it through global_context_paths (features/crush)
  # and Claude Code through a rules file linked below. Not the island agent's notes (~/.config/nihil/nilo.md).
  flake.modules.homeManager.agent-memory = { config, lib, ... }:
    let
      memory = "${config.home.homeDirectory}/.local/share/jarvis/memory.md";
    in
    {
      home.activation.jarvisMemory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "${memory}" ]; then
          run install -Dm644 ${./_memory-template.md} "${memory}"
        fi
      '';

      # Claude Code loads every file in ~/.claude/rules/. Not memory.text/source: those own ~/.claude/CLAUDE.md,
      # which holds my own global rules. The link points at the live file, outside the store.
      home.file.".claude/rules/jarvis-memory.md".source = config.lib.file.mkOutOfStoreSymlink memory;
    };
}
