---
name: prompt-budget
description: Measure the characters and rough tokens of nilo-agent's system prompt plus tool schemas at chat level, before and after an agent change.
---

Run `PYTHONDONTWRITEBYTECODE=1 python3 -I .claude/skills/prompt-budget/measure.py chat [--baseline N]` from the
flake root. It imports `config/nilo-agent/agent.py` offline (no Ollama) and prints the system prompt,
tool schemas and total in characters and about chars/4 tokens. Pass `--baseline` with the earlier total to see
the delta. Baseline at chat level (2026-11-25): 2,549 chars, about 640 tokens. Only its output costs tokens.
