# AGENTS.md — `scripts` repository

Always-on instructions for any AI agent working anywhere under `scripts/`.

This file is the single source of truth. `.github/copilot-instructions.md` points here.

## General directives

- Preferred tool versions are listed in `~mroha/.itools`.
- Builds come along with full tests and test infrastructure. Use agentic TDD.
- Ask clarifying questions.
- `.spec.md` specifications need to be kept up to date and remain good templates for
  future projects.
- `README.md` contains instructions on how to run the script and its tests.

## Python — non-negotiable

**Every new Python project in this repository is a `uv` project with a `pytest` suite.**
This rule is stated here, not only in
[.github/instructions/python-uv-tool.instructions.md](.github/instructions/python-uv-tool.instructions.md),
because that file is gated on `applyTo: "**/*.py"` and therefore cannot fire before the
first `.py` file of a new project exists. By then the wrong choice has already been made.

Scaffold with:

```bash
uv init --package --build-backend uv <tool-name>
cd <tool-name>
uv python pin 3.13
uv add --dev pytest
uv sync
```

If `uv` is missing: `curl -LsSf https://astral.sh/uv/install.sh | sh`.

Required layout:

```txt
<tool-name>/
├── pyproject.toml          # [project.scripts], uv_build backend, [tool.pytest.ini_options]
├── .python-version
├── uv.lock
├── README.md
├── <tool-name>.spec.md
├── src/<module_name>/
│   ├── __init__.py         # re-exports main
│   └── cli.py              # build_parser(), main(argv) -> int
└── tests/
    ├── conftest.py
    └── test_*.py
```

Commands: `uv run <tool-name>`, `uv run pytest`, `uv add`, `uv sync`.

**Never** use `pip`, `python -m venv`, `setup.py`, `requirements.txt`, or
`python -m unittest`. Never place a bare `tool.py` + `test_tool.py` pair at the top of a
project directory.

Reference implementations: [rtl/find_collisions](rtl/find_collisions),
[aisoc/cthrepo-to-zenws](aisoc/cthrepo-to-zenws).

Full conventions, including CLI flags and test rules, are in
[.github/instructions/python-uv-tool.instructions.md](.github/instructions/python-uv-tool.instructions.md).
For the full scaffolding workflow run the `/new-uv-tool` prompt.

## PERL

Build scripts using the same structure as `pprtl2/fixclocks.pl`. For testing use
`Test::More`.

## Markdown

- Surround heading with one blank line above and below.
- Allow no more than 2 consecutive blank lines outside of code fences.
- All fenced code blocks should specify the language for syntax highlighting.
- Trailing spaces should be avoided or be 2 spaces for line breaks.


## Preferences

For scripts that write a `.summary` file, report:

- Command line
- Start time human readable
- End time human readable
- Start time epoch
- End time epoch
