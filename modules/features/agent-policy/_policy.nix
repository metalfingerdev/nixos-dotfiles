# One deny list for every coding agent (Crush, Claude Code). Plain data, no module: the leading
# underscore keeps import-tree from loading it, and the modules that need it import it by path:
#   policy = import ../agent-policy/_policy.nix;
# Rebuilds that change the running system, garbage collection and root are the person's to run (AGENTS.md).
# Building (`nixos-rebuild build`) stays allowed.
rec {
  # Crush's permissions.blocked_commands works on the command name, so a build is prompted for too.
  commands = [ "nixos-rebuild" "nix-collect-garbage" "sudo" ];

  # Claude Code permission rules (settings.json permissions.deny). Deny wins over every mode and allow rule.
  claudeDeny = [
    "Bash(nixos-rebuild switch*)"
    "Bash(nixos-rebuild boot*)"
    "Bash(nixos-rebuild test*)"
    "Bash(nixos-rebuild dry-activate*)"
    "Bash(nix-collect-garbage*)"
    "Bash(sudo *)"
    "Bash(rm -rf /)"
    "Bash(rm -rf /*)"
    "Bash(rm -rf ~*)"
    "Bash(rm -rf $HOME*)"
    "Bash(rm -rf /home/admin*)"
    "Bash(rm -rf ~/nixos-dotfiles*)"
  ];
}
