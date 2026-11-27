"""Characters and a rough token estimate (chars/4) of nilo-agent's system prompt plus tool schemas.

usage: PYTHONDONTWRITEBYTECODE=1 python3 -I measure.py [chat|terminal|system] [--baseline CHARS] [-v]

Imports agent.py without starting anything (no Ollama, no network). Runs with an empty HOME, so the notes
file is not counted (at most CONTEXT_CHARS more in real use, spent on every question).
"""
import importlib.util, json, os, pathlib, sys, tempfile, types

# An empty HOME, so the person's notes file never counts: the number then depends on agent.py alone
os.environ["HOME"] = tempfile.mkdtemp()
os.environ.pop("XDG_CONFIG_HOME", None)

agent = pathlib.Path(__file__).resolve().parents[3] / "config/nilo-agent/agent.py"
spec = importlib.util.spec_from_file_location("nilo_agent", agent)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

args = sys.argv[1:]
level = next((a for a in args if a in ("chat", "terminal", "system")), "chat")
baseline = int(args[args.index("--baseline") + 1]) if "--baseline" in args else None

config = {"language": "en"}
settings = dict(m.DEFAULT_SETTINGS, access=level, model="MODEL")
stub = types.SimpleNamespace(config=config, settings=settings, sees=lambda: False)
tools = m.Tools(stub).schemas(settings)
prompt = m.build_prompt(config, settings)
schemas = json.dumps(tools, ensure_ascii=False)
total = len(prompt) + len(schemas)

print(f"level {level}: tools {[t['function']['name'] for t in tools]}")
print(f"system prompt {len(prompt)} chars, tool schemas {len(schemas)} chars")
print(f"total {total} chars, about {total // 4} tokens")
if baseline is not None:
    delta = total - baseline
    print(f"vs baseline {baseline}: {delta:+d} chars, about {delta // 4:+d} tokens")
if "-v" in args:
    print(prompt)
    print(json.dumps(tools, indent=1))
