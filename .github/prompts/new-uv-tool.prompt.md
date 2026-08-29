---
name: "New uv Python tool"
description: "Scaffold a new Python command-line tool as a uv + pytest project: src layout, console script, --dry-run/--force/--verbose/--help, tests, and a README."
argument-hint: "tool name and what it does, or a path to its .spec.md"
agent: agent
---

Scaffold a new Python command-line tool following [my uv + pytest conventions](../instructions/python-uv-tool.instructions.md).

The user's request (name, purpose, and possibly a spec file) is: ${input}

Steps:

1. **Settle the inputs first.** If a spec file was given, read it and work from it. Ask
   only the questions you cannot answer from the spec or the workspace: tool name,
   required arguments, inputs, and outputs. If the tool reads real data on disk, inspect
   a real sample before designing the parser — never guess a file format.
2. **Create the project** in the requested directory (default: alongside the spec):
   `uv init --package --build-backend uv --description "<purpose>" <tool>`, then
   `uv python pin 3.13` and `uv add --dev pytest`. Add runtime dependencies with
   `uv add`, one command per real need — do not pre-add anything speculative.
3. **Add the pytest config** to pyproject.toml (`testpaths = ["tests"]`, `addopts = "-q"`).
4. **Write the code** as small modules under `src/<tool>/`: pure derivation functions
   separate from I/O, with `cli.py` holding `build_parser()` and
   `main(argv) -> int` only. Support `--help`, `--dry-run`, `--force` and `--verbose`
   with the meanings from the instructions file, plus the tool's own arguments.
5. **Write tests** under `tests/` — one `test_<module>.py` per source module, fixtures in
   `conftest.py`, plus CLI tests for preflight failure, `--dry-run` writing nothing, and a
   full run. Then run `uv run pytest` and get to green.
6. **Write README.md**: purpose, usage with the real command line, inputs, outputs, and a
   Development section (`uv sync`, `uv run pytest`).
7. **Validate against real data** if any exists, and report the actual numbers you got.

Report the created tree, the test result, and the exact command to run the tool.
