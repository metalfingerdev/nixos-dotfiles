# Coding agents

[Docs index](README.md)

| Tool | Use it for | Talks to |
|---|---|---|
| Claude Code (`claude`) | real work on the flake and the island: reads `CLAUDE.md`, which imports `AGENTS.md` | Anthropic (your login) |
| Crush (`crush`) | quick terminal tasks with no cloud | the local Ollama (`qwen3.5:2b`, 8k window) |
| The island's `?` agent (`nilo-agent`) | looking things up and opening apps (Chat); files, git and commands in one repo (Terminal); windows, screen, keys and quick controls (System). Every change, command and desktop action asks first | the local Ollama |

The local model and Claude are kept apart on purpose: nothing sends local content to the cloud. If you want
Claude's help with something the local model wrote, paste it into Claude Code yourself.

The agent is its own repo, `metalfingerdev/nilo-agent` (checked out in `config/nilo-agent`, a flake input like
the dotfiles): a fork of Nihil-Shell's Nilo. Change it there, push, then `nix flake update nilo-agent`. Its
access level is set in the island's conversation.

## Shared pieces

- Deny list `modules/features/agent-policy/_policy.nix`: `nixos-rebuild switch|boot|test`, garbage
  collection, `sudo`/`doas`/`pkexec` and `rm -rf` on `/`, `~` and the repo. Crush reads it as
  `blocked_commands` (by command name, so it asks before a build too), Claude Code as `permissions.deny`,
  merged into `~/.claude/settings.json` on switch (`mutableSettings`). Prefix patterns, not a sandbox: the
  real stops are the sudo password and you running the switch.
- Memory `~/.local/share/jarvis/memory.md`: yours, created once, never overwritten. Keep it under about
  1,000 tokens: it is read at the start of every session, out of the local model's small window. The
  island agent's own notes are separate (`~/.config/nihil/nilo.md`, the Notes button in the conversation).
- Skills in `.claude/skills/` (loaded by Claude Code in this repo): `add-nix-feature`, and `prompt-budget`
  (`PYTHONDONTWRITEBYTECODE=1 python3 -I .claude/skills/prompt-budget/measure.py chat --baseline N`).
  Chat-level baseline: 2,546 characters, about 636 tokens, for the island agent's prompt and tool schemas.

## Rules for agents

See `AGENTS.md`: build, never switch; no global installs (`nix shell nixpkgs#tool -c ...`); no secrets.
