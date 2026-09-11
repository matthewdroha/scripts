# prep_tech

Prepare the Cheetah process technology list files that ctech and synthesis consume.

`prep_tech` reads a markdown input file describing each die's ctech structural
release areas and Cheetah configuration files, resolves every configuration to its
stdcell library root, works out which stdcells the ctech cells actually instantiate,
and writes a per-die tree of verilog/lib/ldb/ndm list files. It is generative and
idempotent: the same inputs always reproduce the same tree. It never runs the
synthesis flow and never modifies a source file.

## Usage

```bash
uv run prep_tech prep_tech.input.md                 # write the tree
uv run prep_tech prep_tech.input.md --check         # validate inputs only
uv run prep_tech prep_tech.input.md --dry-run       # print every planned path
uv run prep_tech prep_tech.input.md --allow-duplicates
```

From another directory: `uv --project /path/to/prep-tech run prep_tech ...`.

### Options

| Flag | Meaning |
| ---- | ------- |
| `--output-root`, `-o` | Where to write. Default `$WORKAREA/prep_tech`, else `./prep_tech`. |
| `--check` | Parse and validate; print a one-line OK summary; write and plan nothing. |
| `--dry-run` | Validate and print every path that would be written; write nothing. |
| `--force` | Accepted for consistency. Every run regenerates the whole tree, so it changes nothing. |
| `--allow-duplicates` | Continue when several configuration files define the same stdcell (first configuration wins). |
| `--verbose` | Log library resolution and each file written. |

### Exit codes

| Code | Meaning |
| ---- | ------- |
| 0 | Success. |
| 1 | Duplicate stdcell definitions found and `--allow-duplicates` was not given. |
| 2 | Pre-flight failure (missing input path, unwritable output, bad `REGEX`). |

## Inputs

| Input | Description |
| ----- | ----------- |
| `prep_tech.input.md` | Markdown. `## <NAME> DIE` / `## <NAME> IP` headings; one absolute path per line underneath. |
| ctech structural release area | A line that is an existing **directory**. Its `ctech_lib*.sv` files are parsed for instantiated stdcells. |
| Cheetah configuration file | A line that is an existing **file**. Its `[DESIGNPACKAGE]` section resolves to one or more stdcell library roots. |
| `REGEX=r"<pattern>"` | Optional suffix on a configuration line, written as a Python raw string (`r"..."` or `r'...'`). All of a die's patterns are unioned to build the optional `*.list.ctech.regex` outputs. |

Lines beginning with `#` (that are not headings) and blank lines are ignored. All
paths are treated as vanity paths and are never symlink-resolved. A `REGEX=` suffix
that is not a raw string literal — including the legacy `REGEX=/.../` form — is a
pre-flight error.

Configuration resolution supports an explicit `<lib_name>` field, direct paths,
recursive `designpackage(name=<pkg>,<field>)` token substitution, compound
`LIB_NAME = g1m_g1i`, auto-detection when `LIB_NAME` is absent, and contour-style
discovery under `path` using the pitch from `lib_height_class`.

## Outputs

```
<output-root>/
├── <die>/
│   ├── static_stdcells.f             # +define+functional, then the referenced bundles' *bmod.v
│   ├── stdcell.lib.list.ctech        # one selected nldm .lib per ctech-referenced bundle
│   ├── stdcell.ldb.list.ctech        # one selected nldm .ldb/.db per ctech-referenced bundle
│   ├── stdcell.lib.list.ctech.regex  # only when the die has a REGEX
│   ├── stdcell.ldb.list.ctech.regex  # only when the die has a REGEX
│   ├── stdcell.lib.list              # all nldm .lib collateral for the used bundles
│   ├── stdcell.ldb.list              # all nldm .ldb/.db collateral for the used bundles
│   └── stdcell.ndm.list              # all ndm collateral for the used bundles
├── prep_tech.report                  # header, per-die summary, per-die statistics
├── prep_tech.csv                     # die,ctech_cell,stdcell,bundle,config,bmod,ctech .sv
└── prep_tech.duplicates.csv          # header always; rows when a stdcell is defined twice
```

The single file per bundle is the nldm-format corner closest to `tttt` / 0.650 V /
100 C, ties broken lexically. Collateral is referenced in place; nothing is copied
or decompressed. Re-running writes in place and does not prune stale files, so remove
a die directory by hand if its input set shrinks.


| File | Description | Typical usage within Intel |
| ---- | ----------- | -------------------------- |
| `static_stdcells.f` | Filelist containing stdcell verilog (may contain UDP definitions) | Stdcell vc_cdc, vcs (RTL) structural run |
| `stdcell.lib.list` | List containing paths to stdcell Liberty files | Conformal and other CDNS tools, most .ldb tools can consume .lib also |
| `stdcell.lib.list.ctech` | Same as above but only the libs required to elaborate ctech | Only where you need to consume RTL but not synthesize |
| `stdcell.ldb.list` | List containing paths to SNPS compiled liberty files | SNPS activities: Power estimation, rtla (no phy), dc, sta/caliber, vclp, fishtail/TCM |
| `stdcell.ldb.list.ctech` | Same as above but only the ldb’s required to elaborate ctech | Only where you need to consume RTL but not synthesize |
| `stdcell.ndm.list` | List containing paths to SNPS .ndm (New Data Model) | Fusion, RTLA (phy aware) |


## Development

```bash
uv sync
uv run pytest
```

Tests are hermetic: fixtures in [tests/conftest.py](tests/conftest.py) build stdcell
release trees, configuration files and ctech sources on `tmp_path`, so nothing
touches a real `/p/hdk` area.

Source modules under [src/prep_tech](src/prep_tech):

| Module | Responsibility |
| ------ | -------------- |
| `config.py` | Parse `prep_tech.input.md` into a dict. |
| `discover.py` | Configuration parsing, DesignPackage resolution, bundle enumeration, PVT/nldm selection, REGEX filtering. |
| `validate.py` | Pre-flight checks. |
| `generate.py` | Per-die plan building, rendering, writing. |
| `cli.py` | `build_parser()` and `main(argv) -> int`. |

The behaviour contract lives in [prep_tech.spec.md](prep_tech.spec.md).
