---
description: "Use when creating or editing a Python project, package, or command-line tool: uv workspace layout, pytest setup, pyproject.toml, console scripts, and the standard --dry-run/--force/--verbose/--help CLI flags."
applyTo: ["**/*.py", "**/pyproject.toml"]
---

# Python projects: uv + pytest

Every Python project is a uv project with a src layout, a console script, and pytest.
Never use bare `pip`, `venv`, `setup.py`, `requirements.txt`, or `python -m unittest`.

## Layout

```
<tool>/
├── pyproject.toml          # uv_build backend, [project.scripts], [tool.pytest.ini_options]
├── .python-version         # pinned by `uv python pin`
├── uv.lock                 # committed
├── README.md               # usage, inputs, outputs, dev commands
├── src/<tool>/
│   ├── __init__.py         # re-exports main(); `__all__ = ["main"]`
│   └── cli.py              # argparse + orchestration only
└── tests/
    ├── conftest.py         # fixtures that build realistic inputs on tmp_path
    └── test_*.py           # one file per source module
```

## Commands

| Task | Command |
| ---- | ------- |
| create | `uv init --package --build-backend uv <tool>` |
| pin python | `uv python pin 3.13` |
| runtime dep | `uv add <pkg>` |
| dev dep | `uv add --dev pytest` |
| sync env | `uv sync` |
| test | `uv run pytest` |
| run the tool | `uv run <tool> ...` (or `uv --project <dir> run <tool> ...` from elsewhere) |

pyproject.toml always carries:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"
```

## CLI conventions

`cli.py` exposes `build_parser()` and `main(argv: Sequence[str] | None = None) -> int`;
`__init__.py` re-exports `main` for `[project.scripts]`. argparse gives `--help` for free —
keep every `help=` string accurate, since it is the tool's real interface.

Standard flags, with these exact meanings:

- `--dry-run` — validate all inputs, print the plan (every path that would be read and
  written), exit 0 without doing expensive work or writing anything.
- `--force` — regenerate outputs that would otherwise be skipped; if the tool always
  regenerates, still accept the flag and say so in `--help`.
- `--verbose` — progress logging through an injectable `log` callable
  (`log = (lambda m: print(f"<tool>: {m}", flush=True)) if args.verbose else None`).
  Flush it: redirected output is block-buffered and a long run looks hung otherwise.

Also:

- Validate every input up front and fail fast with a dedicated exception, printing
  `<tool>: <message>` to stderr and returning a non-zero exit code (2 for preflight).
- Keep derivation pure: functions over in-memory data, no disk access, so they unit-test
  without fixtures. Reserve I/O for the edges.
- Stream large inputs; never read a multi-GB file into memory.

## Tests

- pytest only: plain functions, `tmp_path`, `monkeypatch`, `capsys`, fixtures in
  `conftest.py`. No unittest classes.
- Build fixtures that look like the real data, including its ugly parts (compression,
  odd quoting, embedded spaces) — verify the real format on disk before writing them.
- Cover the CLI end to end: preflight failure exit code, `--dry-run` writes nothing, and
  a full run produces the expected outputs in the expected place.

## README.md

Required in every project, and kept current: one-line purpose, install/usage with the
real command line, a table of inputs, a description of each output, and a Development
section with `uv sync` / `uv run pytest`.
