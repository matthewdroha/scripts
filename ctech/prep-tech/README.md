# prep-tech

## Overview

`prep-tech` is a Python-based project designed to prepare Cheetah process technology list files for ctech and synthesis. It implements a generative and idempotent workflow, ensuring that re-running the process produces the same output from the same inputs without modifying any source files.

## Features

- **Generative Workflow**: Generates output files based on specified inputs.
- **Idempotent**: Re-running the process yields the same results.
- **Validation**: Pre-flight checks to ensure all required files and directories exist.
- **Dry Run Mode**: Allows users to validate inputs and see planned outputs without writing any files.

## Project Structure

```
prep-tech/
├── src/
│   └── prep_tech/
│       ├── __init__.py
│       ├── main.py          # CLI entrypoint (argparse; --check, --dry-run)
│       ├── config.py        # Parses prep_tech.input.md
│       ├── models.py        # Data structures for the project
│       ├── discover.py      # File parsing and design package resolution
│       ├── validate.py      # Pre-flight validation checks
│       └── generate.py      # Output file generation
├── tests/
│   ├── __init__.py
│   ├── test_discover.py     # Unit tests for discover.py
│   ├── test_validate.py      # Unit tests for validate.py
│   └── test_generate.py      # Unit tests for generate.py
├── prep_tech.input.md        # Input specifications for the process
├── prep_tech.spec.md         # Project specifications
├── pyproject.toml            # Project configuration
└── README.md                 # Project documentation
```

## Installation

No third-party runtime dependencies are required. Run directly from the source
tree by putting `src` on the Python path (see Usage). Optionally, install the
package in editable mode (needs `pytest` for the test extra):

```
python3 -m pip install -e .[dev]
```

If PyPI is unreachable, skip the install and use `PYTHONPATH=src` as shown below.

## Usage

Run from the project root with `python3` (not `python`). Put `src` on the path
so the `prep_tech` package resolves without installing:

```
# Validate inputs only (no plan, no write)
PYTHONPATH=src python3 -m prep_tech.main prep_tech.input.md --check

# Plan and print planned outputs without writing
PYTHONPATH=src python3 -m prep_tech.main prep_tech.input.md --dry-run

# Full generation (writes $WORKAREA/prep_tech, or ./prep_tech if WORKAREA unset)
PYTHONPATH=src python3 -m prep_tech.main prep_tech.input.md
```

### Options

- `--check`: Parse and validate the input file only; write and plan nothing.
- `--dry-run`: Validate inputs and print planned outputs without writing any files.

## Testing

Tests are hermetic (they use temporary fixtures and do not touch real release
areas). Run them from the project root:

```
PYTHONPATH=src python3 -m pytest -q
```

Run a single test file, e.g.:

```
PYTHONPATH=src python3 -m pytest tests/test_generate.py -q
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.