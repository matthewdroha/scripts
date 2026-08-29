# find_collisions

Detect RTL modules that are bound to more than one definition (library / config rule /
source file) in a VCS elaboration dump, and report them as an Excel workbook plus a
human-readable run summary.

See [find_collisions.spec.md](find_collisions.spec.md) for the full specification.

## Usage

```bash
uv run find-collisions --fe_collateral <path to fe_collateral> \
    [--modulefile modules.md | --module M] [--paranoia] [--dry-run] [--verbose]
```

Only `--fe_collateral` is required; the other three inputs are auto-discovered from it:

| Source | Discovery |
| ------ | --------- |
| S1 `<BLOCK>_cfg.sv` | inside `fe_collateral/` |
| S2 `rtl_list_2stage.tcl` | inside `fe_collateral/` |
| S3 `fullchipdump.final.py.sort[.zst]` | scraped from `../log/<BLOCK>.v2k_config.syn.log` |
| S4 `config_diagnostics.xml[.gz]` | `VCS_CONFIG_XML` in `../flow_inputs/fullchipdump.config.log` |

`--dry-run` resolves and validates every input, prints the plan, and exits without
parsing the (multi-GB) XML.

## Outputs

Both are written to the current working directory:

- `find_collisions.xlsx`
  - **raw** — every distinct `module + library + configrule + source` of any colliding
    module, with its instance count.
  - **reduced** — per `module + source` rollup after `realpath` canonicalization, kept
    only for modules that still have more than one distinct source. Includes one 1/0
    column per config rule found anywhere in the dump.
- `find_collisions.module.xlsx` — only with `--modulefile` or `--module`. Sheets:
  **patterns** (each pattern plus how many distinct modules it matched), **raw** and
  **reduced** filtered to the matched modules, and **instances** — every `<Instance>`
  of a matched module with its hierarchy path and instantiation site.
- `find_collisions.report` — command line, REF_MODEL/DUT/BLOCK, all four resolved input
  paths, the row count of each sheet, the patterns used, and the `--paranoia` results.

## modulefile

Selects the modules for `find_collisions.module.xlsx`. One or more patterns per line;
blank lines and whole-line `#` comments are ignored. A bare token is an exact module
name; `r"..."` is a regex matched anywhere in the name (so `r"xor"` also matches
`my_xor_gate`). `--module M` is the same as a modulefile containing just `M`.

```
# Test module list for IMH
xor_gate
r"fblp_fcr"
```

## --paranoia

Opt-in cross-file consistency check, reported in `find_collisions.report` under
`paranoia results:`. It never changes the exit code.

1. **XML vs fullchipdump** — every instance should appear in both with the same
   `library / module / module_file / config_rule / parent_file`. Counts per file are
   reported, plus up to 10 full records for each bucket: missing from the fullchipdump,
   missing from the XML, and instances the XML emitted more than once.
2. **`<BLOCK>_cfg.sv` vs XML** — every `instance <hier> liblist <lib>;` binding should
   match the library the elaborator actually used (compared case-insensitively), with
   up to 10 mismatching lines shown.

This roughly triples the runtime: it also streams the compressed fullchipdump and the
multi-GB `_cfg.sv`, and it extracts the hierarchy of every instance in the XML.

## Development

```bash
uv sync          # create/refresh the virtualenv
uv run pytest    # run the test suite
```
