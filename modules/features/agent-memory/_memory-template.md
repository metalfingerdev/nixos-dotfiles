# Shared memory for my coding agents (Crush and Claude Code)

This file is mine: it was created once, and the flake never overwrites it. Edit it freely. Both agents
read all of it at the start of every session, and it is paid for out of the local model's small 8k
window, so keep it under about 1,000 tokens (roughly 4,000 characters). The island's own agent keeps a
separate notes file, ~/.config/nihil/nilo.md.

## Who I am
- (name, what I do, how I like answers: short, plain, no filler)

## This machine
- NixOS on an HP Omen laptop, host "omen", flake in ~/nixos-dotfiles (read its AGENTS.md first).
- Nothing is installed globally by hand: use `nix shell nixpkgs#tool -c ...`. I run switch myself.

## Projects
- ~/nixos-dotfiles: this machine's configuration.
- ~/nixos-dotfiles/config/quickshell: the island (Quickshell shell), its own git repo.
