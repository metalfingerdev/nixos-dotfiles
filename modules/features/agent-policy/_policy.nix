# One deny list for every coding agent (Crush, Claude Code). Plain data, no module: the leading
# underscore keeps import-tree from loading it, and the modules that need it import it by path:
#   policy = import ../agent-policy/_policy.nix { home = "/home/me"; flake = "~/nixos-dotfiles"; };
# `home` is the home folder and `flake` the checkout ($NIXOS_FLAKE) with the home folder written as ~.
# Rebuilds that change the running system, garbage collection and root are the person's to run (AGENTS.md).
# Building (`nixos-rebuild build`) stays allowed for Claude Code; Crush asks first, since it matches the
# command name only. These are prefix patterns, a best-effort guard rather than a sandbox: `sudo` also
# needs a password, which is the real stop.
{ home, flake }:
let
  rmFlags = [ "-rf" "-fr" "-r -f" "-f -r" "-rf --" "-fr --" ];
  rmTargets = [ "/" "/*" "~*" "$HOME*" "${home}*" "${flake}*" ];
  rmRules = builtins.concatMap (f: map (t: "Bash(rm ${f} ${t})") rmTargets) rmFlags;
  # flags may come before the subcommand: `nixos-rebuild --flake .#omen switch`
  rebuildRules = builtins.concatMap
    (sub: [ "Bash(nixos-rebuild ${sub}*)" "Bash(nixos-rebuild * ${sub}*)" ])
    [ "switch" "boot" "test" "dry-activate" ];
in
{
  # Crush's permissions.blocked_commands works on the command name, so a build is prompted for too.
  commands = [ "nixos-rebuild" "nix-collect-garbage" "sudo" "doas" "pkexec" ];

  # Claude Code permission rules (settings.json permissions.deny). Deny wins over every mode and allow rule.
  claudeDeny = rebuildRules ++ [
    "Bash(nix-collect-garbage*)"
    "Bash(*nix-collect-garbage*)"
    "Bash(sudo *)"
    "Bash(* sudo *)"
    "Bash(doas *)"
    "Bash(pkexec *)"
  ] ++ rmRules;
}
