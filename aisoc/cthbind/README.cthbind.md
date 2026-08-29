# cthbind

Generates an augmented aisoc container bindings yaml that includes the
directories required by the current Cheetah shell. See
[cthbind.spec.md](cthbind.spec.md) for the full spec.

## Status

Phase 4 complete: INI parsing (`=` or `:=` separators), directory/PATH
detection, dedup + "Registered by flows" comment generation, yaml
`bindings_tools:` insertion, activity mapping parsing, `cth_query` invocation
with per-flow failure handling (including one no-args `cth_query -resolve`
global call, labeled `GLOBAL`, run once before the per-flow loop to capture
`[LITEINFRA]`), readable-directory-only bindings_tools (unresolved tokens /
plain files are excluded, not just reported), version-floor directory
reduction with multi-slash normalization (`.final`), a post-reduction
generic-directory filter (depth + EDA-tool-root version-basename rules,
including `/p/hdk/rtl/proj_tools/`), a filter that drops candidates already
present in the original yaml's `bindings_tools:`, an optional user-supplied
`--filter` regex exclusion list, an optional `--include` file to force extra
directories in (processed last), a human-readable `.report` (leading with a
count-summary section), incremental `.log` writes, and the CLI
(`--workarea`, `--input-yaml`, `--dry-run`, `--verbose`, `--debug`,
`--filter`, `--include`).

## Usage

```bash
export WORKAREA=/path/to/workarea
export CTH_SETUP_CMD="cth_psetup -p ich/26.03.004 -cfg ich_fe.cth"
export FE_ACTIVITY_MAPPING=$WORKAREA/baseline_tools/activity_dir.map

python3 cthbind.py --input-yaml /path/to/tgs_config.yml [--dry-run] [--verbose] [--debug 1-5] \
  [--filter /path/to/filter.txt] [--include /path/to/include.txt]
```

Outputs are written under `$WORKAREA` (or `--workarea`):

- `<input yaml>.cthbind.orig` — copy of the original input yaml
- `<input yaml>.cthbind.raw` — input yaml with a new block appended to the
  end of `bindings_tools:`; only existing, readable directories are added.
  This is the full, unfiltered extraction — not meant to be used directly.
- `<input yaml>.cthbind.final` — same as `.raw`, but sibling
  directories / a version dir + its own subdirectory are collapsed to their
  common "version floor" (see spec §4), with consecutive slashes normalized
  first; a post-reduction filter then drops existing/readable directories
  that are still too generic (≤4 path segments, or an EDA tool root under
  `/p/hdk/rtl/cad/x86-64_linux*`, `/p/hdk/cad/`, or `/p/hdk/rtl/proj_tools/`
  whose final segment isn't version-like), or already listed in the original
  yaml's `bindings_tools:` section; then, if `--filter` was given, any
  directory matching one of its patterns is dropped; finally, if `--include`
  was given, its directories are appended (bypassing all of the above). This
  is the file meant for actual use in container builds.
- `<input yaml>.cthbind.csv` — raw, unfiltered `flow,section,key,value` rows
  extracted from `cth_query -tool <flow> -resolve` for each flow in the
  activity mapping file
- `<input yaml>.cthbind.log` — written incrementally: header first, then a
  block appended per flow as it's processed (row counts, missing/unreadable
  directory paths)
- `<input yaml>.cthbind.report` — human-readable summary. Leads with a
  "Summary of counts" section (found → found-readable → grouped →
  after-filtering → include-total → include-readable → final-total, plus
  the `.final` path), followed by: missing directories, duplicate
  toolversions across flows, directory-reduction before/after groups,
  directories dropped by the generic-directory filter, the
  already-in-original-yaml rule, and/or `--filter`, and directories added
  via `--include`

`--dry-run` prints the planned output paths (and, with `--verbose`, per-flow
counts) without writing anything. `--debug 5` also dumps raw `cth_query`
output and parsed rows per flow into the log.

`--filter <path>` is optional: a text file of exclusion patterns, one
`"<regexp>"` per line (`#` comments and blank lines ignored). Applied only to
`.final`, after all other filtering — a directory is dropped if any
pattern matches via `re.search` (case-sensitive). The quoted text is compiled
as-is (no unescaping needed — `\/` is already valid regex for a literal `/`).
Example line to drop all `verdi3` binds:
```
"synopsys\/verdi3"
```
If `--filter` is given but the file is missing or unreadable, cthbind exits
with a pre-flight error. Sample:
[cthbind.filter](/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter/cthbind.filter).

`--include <path>` is optional: a text file listing extra directories to
force into `.final`, one per line (blank lines ignored). Every listed
directory is checked pre-flight — it must exist and be readable, or cthbind
exits before doing any `cth_query` work (if a directory is rejected, its
comments below are just discarded, nothing special to do). Processed
**last**, after reduction and all filtering, so these directories bypass the
depth rule, the EDA-tool-root rule, and `--filter`. Added directories are
tagged `# Registered by flows: --include` in `.final`; a directory
already present isn't duplicated but is still listed in the `.report`.

`#` comment lines in the include file are carried over as context: they
accumulate (a blank line does *not* reset them) and attach to the *next*
directory line only, then reset. Multiple consecutive comment lines are
preserved as separate lines. In `.final` they render after the
`# Registered by flows: --include` line and before the directory itself:
```yaml
  # Registered by flows: --include
  # required for nbfeeder install per HSD 1234
  - "/nfs/site/gen/adm/netbatch/nbfeeder/install/2.5.4_0100_05"
```
Comments are not shown in the `.report` `--include` section. Sample:
[cthbind.include](/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter/cthbind.include).

## Tests

```bash
python3 test_cthbind.py -v
```
