# scripts

A collection of utility scripts for automation, development workflows, and system administration.

## Overview

This repository contains scripts organized by purpose to help streamline common tasks. Scripts are written to be portable, well-documented, and easy to use.

## Requirements

- Bash 4.0 or later (for shell scripts)
- Standard POSIX utilities (`grep`, `sed`, `awk`, `curl`, etc.)

## Installation

Clone the repository and optionally add it to your `PATH`:

```bash
git clone https://github.com/matthewdroha/scripts.git ~/scripts
echo 'export PATH="$HOME/scripts/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

Each script includes a usage message accessible via `--help` or `-h`:

```bash
./script-name --help
```

Scripts are organized into subdirectories by category:

| Directory | Description                          |
|-----------|--------------------------------------|
| `bin/`    | General-purpose utility scripts      |
| `dev/`    | Development and build helpers        |
| `ops/`    | System operations and administration |

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-script`
3. Add your script with a usage message and inline documentation
4. Test your script thoroughly
5. Submit a pull request

## License

MIT
