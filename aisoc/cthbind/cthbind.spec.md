# Spec: `cthbind` — Cheetah container bindings generator

Status: **Phase 4 implemented** (2026-08-04) — orig/raw/final/csv/log/report all generated; see §8.
Owner: mroha
Language: **Python 3** (driver), reusing existing Perl helpers
Scope: "start small" — Generate an augmented version of the aisoc container bindings to include what is required for a specific version of Cheetah.

---

## 1. Purpose

`cthbind` scans an active Cheetah shell and existing aisoc container yaml bind file as input,  and produces a new aisoc container yaml bind file that includes the new Cheetah release.  The new bind file is suitable for use in future aisoc container builds.

The workflow is **generative and idempotent**: re-running it reproduces the same output
tree from the same inputs.

---

## 2. Inputs (sources of truth)

Lines beginning with `#` are comments and ignored.  Blank lines are ignored.  The following table summarizes the inputs to the workflow.

| # | Source | Provides | Notes |
|---|--------|----------|-------|
| S1 | **Reference yaml for container bindings** — e.g. /p/cth/pu_tu/prd/gatekeeper_configs/aisoc/latest/lib/container_configs/tgs_config.yml | Starting yaml container bindings file to build on | In the output make a copy of this file with a .orig suffix|
| S2 | **Current Cheetah shell** — e.g. The current working environment.  Using successive cth_query calls to extract tool versions, paths, and other relevant information |  |
| S3 | **Activity mapping file** - e.g. The file pointed to by $FE_ACTIVITY_MAPPING.  If the variable is a relative path,  then assume the root path is $WORKAREA | List of flows to use for cth_query -tool <flow> call| |


For your own testing to set up a Cheetah shell,  you can use the following command:

```bash
/p/hdk/bin/cth_psetup -p ich/26.03.004 -cfg ich_fe.cth
export WORKAREA=/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter
```

---

## 2.1 cth_query utility

Within the current Cheetah shell, `cth_query` is used to extract the following information from Cheetah,  which is in key=value pairs using .INI format:
- Environment settings:  Under the [ENVS] section of the cth_query output
- Params:  Under the [PARAMS] section of the cth_query output
- Toolversions:  Under the [TOOLVERSION] or [TOOLVERSION_<OS>] section of the cth_query output
- License: Under the [LICENSE] section of the cth_query output.  License feature names.
- LiteInfra: Under the [LITEINFRA] section of the cth_query output.  LiteInfra paths and versions.

The [] sections are case-insensitive.
So [TOOLVERSION] and [toolversion] are equivalent.  Uppercase is used in all outputs for these sections.

Key/value lines within a section may use either `=` or `:=` as the separator (whitespace around
either is trimmed). For example, both of the following parse to the same `(key, value)`:
```
	VCS_VERSION = X-2025.06-SP2
	default_python_version := 3.13.2
```
yields `key="default_python_version"`, `value="3.13.2"`.

Usage: `cth_query -tool <flow>` will dump the entire INI format for a specific flow.  The output can be parsed to extract the relevant information for the tool.

In addition to the per-flow `cth_query -tool <flow> -resolve` calls, cthbind runs one extra
`cth_query -resolve` call **with no `-tool` flag**, exactly once per run (before the per-flow
loop). This captures environment-wide state that isn't tied to any single flow, notably the
`[LITEINFRA]` section. Its rows are tagged with the fixed flow label `GLOBAL` (activity `n/a`)
and otherwise flow through the same pipeline as any flow's rows: eligible for bindings_tools
directory extraction, known-version-value collection (for `.final`), the `.csv`, and the
`.log`. If this call fails, it's treated like any other flow failure (logged, run continues,
cthbind exits non-zero at the end).


## 2.2 Activity mapping file

The activity mapping file is a text file containing the following format:
<FLOW> <ACTIVITY>
The FLOW field is the list of Cheetah flows to use for cth_query -tool <flow> call.  The ACTIVITY field is the corresponding activity name to use in the output yaml file.
The ACTIVITY field is used to determine which directory under $WORKAREA the flow needs to run.

For example,  for activity mapping row

```txt
vcssim verif
```

The vcssim flow will be run under the $WORKAREA/verif directory.


## 2.2  Validation (pre-flight)

The following must be set at the time of flow execution.  Otherwise an error is raised.
- `$WORKAREA` must be set and is a valid directory path.
- `$CTH_SETUP_CMD`must be set
- `$FE_ACTIVITY_MAPPING` must be set and is a valid file.  See rules above on handling relative path to file.
- Input container yaml file must exist and be readable.
- If `--filter` is given, the file it points to must exist and be readable.
- If `--include` is given, the file it points to must exist and be readable, **and** every
  directory listed inside it must exist and be a readable directory (checked before any
  `cth_query` calls are made — a "quick rejection" check).


## 3. Outputs (the generated tree)

```
$WORKAREA
├── <input yaml>.cthbind.orig                    # Copy of original input yaml
├── <input yaml>.cthbind.raw                     # Generated by cthbind: full, unfiltered extraction
├── <input yaml>.cthbind.final                   # Generated by cthbind: grouped, filtered, +includes — the file meant for actual use
├── <input yaml>.cthbind.csv                     # Output .csv file containing the extracted information from cth_query
|── <input yaml>.cthbind.log                     # Log file information about the cthbind run
|── <input yaml>.cthbind.report                  # Human readable report of the cthbind run (leads with a count summary)
```

---

## 4. Per-output derivation rules

**<input yaml>.cthbind.orig:** Direct copy of the input yaml file, renamed with a `.cthbind.orig` suffix.

**<input yaml>.cthbind.raw:** Copy of the input yaml file, but with the following modifications:
  - Only add changes,  no lines will be deleted
  - The only changes will be to the "bindings_tools:" section of the yaml file.  The new section will contain a deduplicated directories extracted from the cth_query output. The new section will be added to the end of the "bindings_tools:" section of the yaml file.
  - Use the <input yaml>.cthbind.csv as input to determine which directories to add to the new yaml file.  The csv file will contain a list of directories extracted from the cth_query output for each flow in the activity mapping file.

  If the same directory is required by multiple flows,  it will only be added once to the cthbind section of the yaml file. A comment will be added with the below format to indicate which flow(s) required the directory.  For example, if the same directory is required by both the vcssim and vcs flows,  the comment will be:
```yaml

bindings_tools:
<original yaml content>
# Start cthbind additions
# Registered by flows: vcssim vcs
- "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vcsmx/X-2025.06-SP2"
<more cthbind adds>
# Finish cthbind additions
```

  Only directories that exist on disk **and** are readable are added here (see the
  readable-directory gate in §6) — unresolved template tokens (e.g.
  `toolversion(CDC_METHODOLOGY_VERSION)`) and plain files are excluded from `.raw`
  (and `.final`), but are still recorded in the `.csv` (raw/unfiltered) and
  reported in `.log` and in the `.report` "Summary of missing directories" section.

**<input yaml>.cthbind.final:** Copy of the <input yaml>.cthbind.raw file, but with some directory reduction functions applied to the raw yaml file to reduce the directory count.  Guideline is to find the common version of given directory tree.

Example:
  - "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6/OneSourceGen"
  # Required by flows: crflow fuseflow
  - "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6/OneSourceXmlApi"
  # Required by flows: crflow
  - "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6/OneSourceIntegrator"
  # Required by flows: crflow fuseflow
  - "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6/OneSourceValidator"
  # Required by flows: crflow fuseflow
  - "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6/OneSourceStudio"

  Gets reduced to:

  - "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6"

  This above directory is only listed once.  The comment will contain a union of all of the
  flows that required the original directories.  In this case,  the comment will be:
  # Registered by flows: crflow fuseflow



  OR another example:

  # Registered by flows: vcformal
  - "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1"
  # Registered by flows: vcformal
  - "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1/bin"

  Gets reduced to:
  - "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1"

  **Algorithm (implemented):** for every accepted (readable) bindings_tools directory,
  compute its "version floor" — the path truncated to end at its *deepest* path segment
  that exactly matches a known version value (collected from that run's `[TOOLVERSION]`,
  `[TOOLVERSION_<os>]`, and `[LITEINFRA]` values whose digit count is ≥ 4, digits need not
  be contiguous). Directories are then re-grouped by their floor, merging flows (union,
  first-seen order). A path with no matching segment is left unchanged (safest default —
  never collapses further than a confirmed version segment, and never collapses to a bare
  tool directory like `.../synopsys/vcsmx`, since matching against *known extracted version
  values* — not a generic per-segment digit count — avoids false positives like
  `x86-64_linux26`, which contains digits but is never an extracted TOOLVERSION/LITEINFRA
  value). This one rule produces both reduction patterns above: sibling subdirectories of an
  unbound version dir share the same computed floor and collapse together; a version dir
  bound alongside its own subdirectory both compute to the same floor (themselves) and
  collapse together.

  **Multi-slash normalization:** before the floor is computed, directories have any run of
  consecutive slashes collapsed to one (as the filesystem itself would resolve them). This
  means two raw extractions of the *same* directory that merely differ in slash count merge
  into a single entry, e.g.:
  ```yaml
  # Registered by flows: rtla
  - "/p/hdk/cad/rtla//X-2025.06-SP2"
  # Registered by flows: rtla rtlaqor
  - "/p/hdk/cad/rtla/X-2025.06-SP2"
  ```
  reduces to a single `- "/p/hdk/cad/rtla/X-2025.06-SP2"` line with `# Registered by flows: rtla
  rtlaqor`. (`.raw` is unaffected — it still lists whatever raw strings `cth_query` produced.)

**Post-reduction generic-directory filter (`.final` only):** after the version-floor
reduction above, a further filter drops directories that exist and are readable but are judged
too generic/versionless to be useful bindings. Applied in this order:

1. **Depth rule (applied first):** drop any directory with 4 or fewer path segments
   (e.g. `/p/hdk/cad/conformal`, `/usr/intel/bin`, `/p/hdk/pu_tu/prd`); a directory with 5+
   segments survives this rule (e.g. `/p/hdk/cad/conformal/25.20-p100`).
2. **EDA-tool-root version-basename rule:** for directories under `/p/hdk/rtl/cad/x86-64_linux*`,
   `/p/hdk/cad/`, or `/p/hdk/rtl/proj_tools/` (at any depth beneath those roots), drop the
   directory unless its *final* path segment looks like a version — at least 2 digit characters,
   not necessarily contiguous (a lower threshold than the 4-digit gate used for known-version
   matching above; this is a separate, basename-only heuristic). Examples:
   - `/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer` → dropped (`visualizer` has 0 digits)
   - `/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer/w230217` → kept (`w230217` has 6 digits)
   - `/p/hdk/cad/mint/v25ww40` → kept (`v25ww40` has 4 digits)
   - `/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/` → dropped (`VisaIT` has 0 digits; trailing
     slash is stripped before taking the final segment)
   - `/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/5.4` → kept (`5.4` has 2 digits)
   - `/p/hdk/rtl/proj_tools/vc_methodology_lint/master` → dropped (`master` has 0 digits)
   - `/p/hdk/rtl/proj_tools/vc_methodology_lint/master/2.02.23.25ww19` → kept

   Directories outside those three roots are not subject to rule 2 at all.
3. **Already-in-original-yaml rule:** a directory is dropped if it's already listed in the
   *original* yaml's `bindings_tools:` section (only that section — `bindings_sys:` and
   `bindings_design:` are not checked). Entries there may be a plain path or Singularity
   `src:dest` bind syntax (quoted or not); only the source (left of the first `:`) is compared,
   normalized the same way as extracted candidates (multi-slash collapsed, trailing slash
   stripped). This prevents cthbind from re-adding (and duplicating) a directory the yaml already
   binds, e.g. if `- "/p/hdk/cad/rtla/X-2025.06-SP2"` is already present, a freshly-extracted
   candidate for the same directory is dropped rather than appended a second time.
4. **User-supplied `--filter` regex file (optional, applied after rules 1-3):** if `--filter
   <path>` is given, each non-comment, non-blank line of that file must be `"<regexp>"` — a
   regular expression enclosed in double quotes (e.g. `"^\/p\/hdk\/rtl\/cad\/x86-64_linux26\/$"`).
   The quoted text is passed to `re.compile()`/`re.search()` verbatim; no unescaping is performed
   (`\/` etc. are already valid regex syntax for a literal character, so paths containing `/` work
   without any special handling). Lines starting with `#` are comments; blank lines are ignored.
   Every surviving directory (after rules 1-3) is checked against every pattern with
   `re.search` (case-sensitive); if *any* pattern matches, the directory is dropped. `--filter`
   only affects `.final` — `.raw` is never filtered by it. Example line:
   `"synopsys\/verdi3"` drops any directory containing `synopsys/verdi3`. If `--filter` is given
   but the file doesn't exist or isn't readable, cthbind exits with a pre-flight error (like the
   other required inputs). Sample file:
   `/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter/cthbind.filter`.

Directories dropped by the generic filter (rules 1-2), the already-in-yaml rule (rule 3), or
`--filter` (rule 4) are recorded in the `.report` "Summary of directories filtered from .final"
section (with the flow(s) and a reason — which rule, or which `--filter` pattern, triggered
removal); they are not removed from
`.raw`, which always reflects the full unfiltered/unreduced extraction.

**User-supplied `--include` file (optional; processed last, after reduction and all filtering):**
if `--include <path>` is given, its non-blank lines are read as one directory per line, with `#`
comment lines carried along as context (see below). Every listed directory is checked pre-flight
("quick rejection"): it must exist and be a readable directory, otherwise cthbind exits with a
fatal error before doing any `cth_query` work (same rigor as the other required inputs) — if a
directory is rejected this way, its associated comment(s) are simply discarded along with it, no
special handling needed. After reduction and all filtering (rules 1-3 above) are complete, each
include directory is appended to the final `.final` bindings_tools list — tagged with
`# Registered by flows: --include` (reusing the normal comment format, with `--include` standing
in for a flow name) instead of a real flow list, so it's clear the entry was force-added rather
than extracted from `cth_query`. An include directory that's already present in the
(reduced/filtered) list is **not** duplicated, but is still reported. `--include` never affects
`.raw`. Sample file: `/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter/cthbind.include`.

**Carried-over comments:** `#` comment lines in the include file accumulate (blank lines do not
reset them) and attach to the *next* directory line encountered; the accumulator then resets, so
a comment block only carries over to the single directory immediately following it — not to
every subsequent directory. Multiple consecutive comment lines are preserved as separate `#`
lines, in original order. In `.final`, a directory's carried-over comment(s) render *after*
the `# Registered by flows: --include` line and *before* the `- "..."` list entry, e.g.:
```yaml
  # Registered by flows: --include
  # required for nbfeeder install per HSD 1234
  - "/nfs/site/gen/adm/netbatch/nbfeeder/install/2.5.4_0100_05"
```
Comments are not shown in the `.report` "Summary of directories added via --include" section
(that section only lists the directory and its added/skipped status).

Directories from `--include` are recorded in the `.report` "Summary of directories added via
--include" section, in file order, each marked `added` or `skipped (already present in
.final)`.




**<input yaml>.cthbind.csv:** CSV file containing the extracted information from cth_query for each flow in the activity mapping file.  The CSV file will have the following columns:
- flow: The flow name from the activity mapping file
- section: The section name from the cth_query output (ENVS, PARAMS, TOOLVERSION, LICENSE, LITEINFRA)
- key: The key name from the cth_query output
- value: The value associated with the key from the cth_query output

The output is calculated using the following method:
1. For each flow in the activity mapping file, run `cth_query -tool <flow> -resolve` and capture the output.
2. Parse the output to extract the relevant information for each section

The [LICENSE] section may appear more than once in the cth_query output.  In that case,  the output will contain multiple rows for the same flow and section, ONLY extracting the 'Feature' key and its associated value.  The output will contain one row for each unique feature in the [LICENSE] section.

**<input yaml>.cthbind.log:** Log file containing information about the cthbind run.

Write to the log file at the start of the run, and append to it as each flow is processed.  The log file will contain a header and a body.  The header will be written at the start of the run, and the body will be appended to as each flow is processed.  This will provide some indication of progress while executing.

The header will contain the following information:
- Command line used to run cthbind
- Human readable start date and time of the run
- Epoch time of the start date and time of the run
- Machine name where the run was executed
- Current working directory where the run was executed

The body of the log file will contain the following information:
- For each flow in the activity mapping file, the following information will be logged:
  - Flow name
  - Number of rows extracted from the cth_query output for the flow
  - Report any row whose value is a directory path and that path does not exist and is non-readable on disk.  The report will include the flow name, section, key, and value for each missing directory path.
  - If the row value is a PATH format (i.e. colon-separated list of directories),  then each directory in the PATH will be checked for existence and readability.  Any missing directories will be reported in the log file with the flow name, section, key, and value for each missing directory.

- Report flow complete and number of non-existent directories set but not readable for the flow.


**<input yaml>.cthbind.report:** Human readable report of the cthbind run.

Will improve over time by adding summary sections. Sections always appear in this order,
separated by a blank line; every one is always present (even if empty).

**Section 0 (leads the file): "Summary of counts"** — one line per metric, no comments needed
since the labels are self-explanatory. This gives a quick funnel view of how many directories
survived each stage without having to read the rest of the file. Use the following format:
```
# Summary of counts
Total directories found in cth_query registry (deduplicated): <count>
Total readable directories found in cth_query registry: <count>
Total readable directories after grouping: <count>
Total readable directories after filtering: <count>
Total directories provided in --includes: <count>
Total readable directories provided in --includes: <count>
Final bindings added to output yaml: <count>
Output yaml: <full path to .cthbind.final>
```
- "found" = deduplicated candidate directories extracted from `cth_query` (same set `.raw` is
  built from), before the readable-directory gate.
- "found readable" = the subset that passed the readable-directory gate (`partition_readable()`).
- "after grouping" = count after version-floor reduction/grouping (§4), before any filtering.
- "after filtering" = count after the generic-directory filter, the already-in-yaml rule, and
  `--filter`, but *before* `--include` is applied.
- the two `--includes` lines report the include file's total directory count and how many of
  those are (already guaranteed, by the pre-flight "quick rejection" check, to be) readable —
  in a successful run these two numbers always match, since an unreadable include directory
  aborts the run before any of this is computed.
- "Final bindings added to output yaml" = the total directory count actually written to
  `.final`'s `bindings_tools:` block (after filtering *and* `--include`).

**Section 1: "Summary of missing directories"**
- Consolidated list of all missing directories across all flows, deduplicated, and sorted.  Each missing directory will be reported with the flow name(s) that required it.  Use the following format:
```
# Summary of missing directories
# Required by flows: <flow1> <flow2> ...
/missing/directory/path1
/missing/directory/path2


**Section 2: "Summary of duplicate toolversions"**
- For each [TOOLVERSION] key,  list only the key-value pairs that have more than one value across all flows.  For each duplicate key,  list the flows that set this version. Use the following format:
```
# Summary of duplicate toolversions
# Total unique keys with at least one duplicate value: <num_unique_keys>

# Unique keys with duplicate values:
<key1>    Total Unique Values: <num_unique_values>
<key2>    Total Unique Values: <num_unique_values>
<key3>    Total Unique Values: <num_unique_values>

# TOOLVERSION key: <key>    Total Unique Values for this TOOLVERSION: <num_unique_values>
# Required by flows: <flow1> <flow2> ...
key=<value1>
# Required by flows: <flow3> <flow4> ...
key=<value2>
```


**Section 3: "Summary of directory reductions for .final file"**

Group Before reduction:
  # Registered by flows: vcformal
  - "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1"
  # Registered by flows: vcformal
  - "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1/bin"

Group After reduction:
  # Registered by flows: vcformal
  - "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1"

Only groups where a reduction actually happened (more than one original directory, or a
single directory whose path was truncated) are listed; unchanged directories are omitted.

**Section 4: "Summary of directories filtered from .final (generic / versionless)"** — every
directory dropped by the generic-directory filter, the already-in-yaml rule, or `--filter`,
each with its contributing flow(s) and a `# Reason:` line (see §4 and §6 for the exact rules).

**Section 5: "Summary of directories added via --include"** — every `--include` directory, in
file order, each marked `added` or `skipped (already present in .final)` (comments from the
include file are not repeated here — see `.final` itself for those).

---

## 5. CLI (proposed)

```
cthbind.py \
  --workarea    <path>          # default: $WORKAREA
  --input-yaml  <path>          # No default, required.
  [--dry-run] [--verbose] [--help] [--debug <level>] [--filter <path>] [--include <path>]
```

Behavior:
- `--dry-run` prints the planned actions/paths without writing.
- `--verbose` prints more information about the run, including summary counts from each flow.
- `--debug <level>` prints debug information to the log file at the specified level (1-5). Make sure it has a debug header. The debug level will determine how much information is printed to the log file. At it's highest level, the log will show the raw cth_query output for each flow, and the parsed rows that are extracted from the output. 
- `--filter <path>` (optional): a text file of exclusion patterns, one `"<regexp>"` per line
  (`#` comments and blank lines ignored), applied to `.final` only, after all other
  filtering (see §4). A directory is dropped if any pattern matches it (`re.search`,
  case-sensitive). Filtered directories are listed in the `.report` file. Fatal pre-flight error
  if given but the file doesn't exist/isn't readable.
- `--include <path>` (optional): a text file listing extra directories to force into
  `.final`, one per line (`#` comments and blank lines ignored). Every listed directory
  must exist and be readable (checked pre-flight; fatal error otherwise). Processed **last**,
  after reduction and all filtering (`--filter` included) — these directories bypass the depth
  rule, the EDA-tool-root rule, and `--filter` entirely. Added directories are tagged
  `# Registered by flows: --include` in `.final` and listed in the `.report` file.

---

## 6. Resolved questions & remaining notes

- **Directory-eligible sections:** ENVS, PARAMS, TOOLVERSION, LITEINFRA are all eligible for
  bindings_tools extraction (LICENSE rows are feature names, never directories, and are excluded).
  In practice TOOLVERSION rows are usually version strings (e.g. `25.03.004`), not paths, and are
  naturally filtered out by the directory-detection rule below.
- **Key/value separator:** `=` and `:=` are both accepted (checked via a single regex,
  `\s*:=\s*|\s*=\s*`, applied per line); whitespace around the separator is trimmed either way.
- **Directory detection rule:** a value is treated as a candidate directory if it starts with `/`.
- **Readable-directory gate (supersedes the original "added regardless of existence" rule):**
  a candidate is only added to `.raw`/`.final` if it exists on disk **and** is a readable
  directory (`os.path.isdir()` + `os.access(R_OK)`). This excludes unresolved template tokens
  (e.g. `toolversion(CDC_METHODOLOGY_VERSION)`) and plain files (e.g. a `.spq` file) that were
  leaking into bindings_tools. Excluded candidates are still recorded in the raw `.csv`, reported
  per-flow in `.log`, and consolidated (deduplicated, sorted, with contributing flows) in the
  `.report` "Summary of missing directories" section.
- **PATH-style values:** colon-separated values are split into individual directories. Each
  directory is checked for existence (log if missing) and is itself a candidate for bindings_tools,
  subject to the noise filter below.
- **PATH noise filtering:** relative entries (e.g. `.`) and well-known system dirs
  (`/bin`, `/usr/bin`, `/usr/local/bin`, `/usr/lib*`, `/lib*`) are excluded from bindings_tools
  candidates (still eligible for the CSV / existence-check log).
- **Activity directory context:** `cth_query -tool <flow> -resolve` is always run from the current
  shell/cwd; cthbind does **not** chdir into `$WORKAREA/<activity>` first. ACTIVITY is metadata only
  at this stage (not yet consumed further).
- **-resolve flag:** always used for every `cth_query` invocation.
- **Output file naming:** outputs keep the full input filename including extension, e.g.
  `tgs_config.yml.cthbind.orig`, `tgs_config.yml.cthbind.raw`, `tgs_config.yml.cthbind.final`,
  `tgs_config.yml.cthbind.csv`, `tgs_config.yml.cthbind.log`, `tgs_config.yml.cthbind.report`,
  written under `$WORKAREA`. (`.raw`/`.final` were named `.new`/`.new.reduced` before Phase 4 —
  renamed for clarity: `.raw` is the unfiltered extraction, `.final` is what's actually meant to
  be used.)
- **Flow failure handling:** if `cth_query -tool <flow> -resolve` fails (non-zero exit or
  empty/malformed output) for a flow, log an error for that flow and continue with the remaining
  flows; cthbind exits non-zero at the end if any flow failed. The single no-args global call
  (see §2.1) is treated identically.
- **Global no-args call:** `cth_query -resolve` (no `-tool`) is run exactly once per cthbind
  invocation, before the per-flow loop, primarily to capture `[LITEINFRA]`. Its rows use the
  fixed label `flow=GLOBAL`, `activity=n/a` and are otherwise fully eligible (bindings_tools
  candidates, known-version values, CSV, log) — same treatment as any per-flow result.
- **New entry quoting style:** newly added bindings_tools lines are double-quoted
  (`- "/path/..."`) to match the existing file convention (see `uic_config.yml` fixture).
- **Flow-attribution wording:** "Registered by flows" is used everywhere (`.raw`, `.final`,
  and all `.report` sections) — a deliberate rename from the original "Required by flows".
- **Dedup scope:** dedup among newly-extracted directories (across flows) is unconditional and
  applies to both `.raw` and `.final`. Cross-checking against **pre-existing** yaml
  `bindings_tools:` entries (the "already-in-original-yaml rule", §4 rule 3) only happens for
  `.final` — `.raw` still may end up duplicating an existing line, unchanged from the
  original behavior.
- **.final derivation:** built from the same accepted (readable) candidate list as `.raw`, with
  the version-floor reduction applied before insertion into a fresh copy of the original yaml —
  not by textually re-parsing the `.raw` file.
- **Version-floor reduction algorithm:** see the worked example and rule under §4
  (`<input yaml>.cthbind.final`). Known-version values are gathered from `[TOOLVERSION]`,
  `[TOOLVERSION_<os>]`, and `[LITEINFRA]` rows across *all* flows (not just the flow that produced
  a given directory), filtered to values with ≥ 4 digit characters (digits need not be contiguous).
  A directory's "floor" is itself truncated at the deepest path segment that exactly equals one of
  these values; matching against real extracted values (rather than counting digits in path
  segments directly) is what keeps this safe — e.g. `x86-64_linux26` contains 6 digits but is never
  itself an extracted TOOLVERSION/LITEINFRA value, so it is never mistaken for a version segment.
- **.report "Summary of missing directories" scope:** limited to bindings_tools candidates that were
  excluded by the readable-directory gate (i.e. the same set as `partition_readable()`'s second
  return value) — not the full universe of existence-checked PATH entries (which includes
  intentionally noise-filtered system dirs).
- **.report "Summary of duplicate toolversions" scope:** limited strictly to rows in the `[TOOLVERSION]`
  section (not `[TOOLVERSION_<os>]` variants).
- **Multi-slash normalization:** applied only during `.final` construction (as part of
  `reduce_bindings_additions`), not to `.raw`; two raw extractions of the same directory that
  differ only in slash count (e.g. `rtla//X-2025.06-SP2` vs `rtla/X-2025.06-SP2`) merge into one
  entry once normalized.
- **Generic-directory filter (`.final` only):** a post-reduction step drops existing/readable
  directories that are still too generic to be useful bindings_tools entries — see the rules
  (depth ≤ 4 segments; EDA-tool-root final-segment-must-look-like-a-version, with a 2-digit
  threshold distinct from the 4-digit threshold used for version-floor matching, applied under
  `/p/hdk/rtl/cad/x86-64_linux*`, `/p/hdk/cad/`, and `/p/hdk/rtl/proj_tools/`) documented under
  §4. `.raw` is unaffected (always the full, unfiltered extraction). Filtered-out directories are
  recorded in the `.report` "Summary of directories filtered from .final" section, not silently
  dropped.
- **Already-in-original-yaml filter (`.final` only):** cross-checks each surviving candidate
  against `parse_existing_bindings_tools()`, which scans only the original yaml's
  `bindings_tools:` section (not `bindings_sys:`/`bindings_design:`) and extracts the *source*
  side of each entry (splitting on the first `:` to strip Singularity `dest` targets), normalized
  the same way as extracted directories. A match is dropped from `.final` and reported with
  reason "already present in original yaml bindings_tools:" in the same `.report` section as the
  generic filter. `.raw` is unaffected (per the existing "Dedup scope" note, it may still
  duplicate a pre-existing line).
- **`--filter` regex file:** optional, applied last of the reduction-time filters (after the
  generic-directory filter), only to `.final`. Format is `"<regexp>"` per line (double-quote
  delimited, not slash-delimited), `#` comments and blank lines ignored; the quoted text is
  compiled as-is (no unescaping — `\/` is already valid regex for a literal `/`, so paths match
  naturally). Matching is `re.search` (partial match, anywhere in the path), case-sensitive;
  multiple patterns combine with OR (any match drops the directory). A given but
  missing/unreadable `--filter` file is a fatal pre-flight error, same rigor as the other required
  inputs. Matches are recorded in the same `.report` "Summary of directories filtered from
  .final" section as the generic filter, with a reason identifying the matched pattern.
- **`--include` file:** optional, processed **after** reduction and all filtering (generic filter
  + `--filter`) — i.e. it's the last step before `.final` is written, and its directories
  bypass every other rule. Format is one directory per line, blank lines ignored; `#` comment
  lines are captured as context (see below) rather than simply discarded. Every listed directory
  is validated pre-flight ("quick rejection"): must exist and be a readable directory, else
  cthbind exits before doing any `cth_query` work — this reuses `is_readable_dir()`, the same
  check used for the readable-directory gate on extracted candidates; if a directory is rejected,
  its associated comments are dropped too, no special handling needed. Directories are appended
  to `.final` tagged `# Registered by flows: --include` (reusing the existing comment
  format rather than inventing a new one — `--include` simply stands in for a flow name, which
  conveys the origin without new rendering logic). An include directory identical to one already
  present in the (reduced/filtered) list is not duplicated, but is still listed in the `.report`
  "Summary of directories added via --include" section (in file order) with a status of `added`
  or `skipped (already present in .final)`. `--include` never affects `.raw`.
- **`--include` comment carry-over:** `#` comment lines accumulate (blank lines do not reset the
  accumulator) and attach to the *next* directory line only; the accumulator resets after each
  attachment, so a comment block never carries over to more than one directory. Multiple
  consecutive comment lines are preserved as separate lines, in order. Rendered in `.final`
  *after* the `# Registered by flows: --include` line and *before* the directory's `- "..."` list
  item (`BindingEntry` gained a `comments: list[str]` field for this, defaulting to empty for
  every non-`--include` entry, so normal extraction/rendering is unaffected). Comments are not
  duplicated into the `.report` `--include` section.
- **.report "Summary of counts" section (leads the file):** a `RunCounts` snapshot taken at seven
  specific points in the pipeline (found → found-readable → grouped → after-filtering →
  include-total → include-readable → final-total), plus the resolved `.final` path. See §4 for
  the exact metric definitions; this section exists purely to give an at-a-glance funnel view and
  duplicates no other section's detail.
- **.log incremental writes:** the header is written immediately (before any `cth_query` calls); each
  flow's body section is appended right after that flow finishes, so the log shows progress while
  cthbind is still running. Skipped entirely in `--dry-run`.
- **CSV stays raw:** the bug fix (readable-directory gate) only affects bindings_tools
  candidates/output files; `.cthbind.csv` continues to record every extracted row unfiltered.
- **Fixtures:** sample `cth_query -resolve` output and sample container-bindings yaml are available at
  `/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter/cth_query.sample` and
  `/nfs/site/disks/aisoc.tfm.01/mroha/simple_counter/uic_config.yml` for building the parser and
  unit-test fixtures. Note real `cth_query` sections use mixed-case headers (`[Envs]`,
  `[ToolVersion]`, `[ToolVersion_<os>]`, `[License]`) with tab-indented `Key = Value` lines; existing
  yaml bind entries may use Singularity `src:dest` syntax, not just plain paths.

---

## 7. Test plan

Start small, table-driven, no live tool dependency in unit tests.
Include integration and smoke tests as we proceed in development.

1. **Unit — INI parsing:** parse the fixture `cth_query.sample`, assert rows for
   `ENVS`/`TOOLVERSION`/`TOOLVERSION_<os>`/`LICENSE` (case-insensitive headers normalized to
   uppercase; repeated `[License]` blocks collapse to unique `Feature` rows only; `=` and `:=`
   separators both parse correctly, including when mixed within the same section).
2. **Unit — directory detection & PATH splitting:** given sample rows (plain path, PATH-style
   colon list, version string, relative `.`, well-known system dir), assert which become
   bindings_tools candidates per the starts-with-`/` rule and the noise filter.
3. **Unit — dedup & comment generation:** given rows from multiple flows sharing a directory,
   assert the directory appears once with a `# Registered by flows: <flow1> <flow2>` comment,
   double-quoted, in stable (first-seen) order.
4. **Unit — yaml bindings_tools insertion:** given a fixture yaml (e.g. `uic_config.yml`), assert
   the `.cthbind.raw` output is byte-identical to the input except for the appended
   `# Start/Finish cthbind additions` block at the end of `bindings_tools:`.
5. **Unit — activity mapping parsing:** parse a fixture mapping file, assert comments/blank
   lines ignored and `(flow, activity)` pairs extracted; relative `$FE_ACTIVITY_MAPPING` resolved
   against `$WORKAREA`.
6. **Integration (mocked):** stub `cth_query` invocations with fixture output per flow; assert
   `.orig`/`.raw`/`.final`/`.csv`/`.log`/`.report` are all produced correctly and `--dry-run`
   writes nothing.
7. **Integration — flow failure:** one stubbed flow returns non-zero/empty output; assert it's
   logged as an error, remaining flows still run, and cthbind exits non-zero.
8. **Unit — readable-directory gate:** given candidates pointing at a real directory, a plain file,
   and a nonexistent path (including an unresolved `toolversion(KEY)` token), assert only the real
   directory is accepted and the rest are reported as missing.
9. **Unit — version-floor reduction:** given known TOOLVERSION/LITEINFRA values, assert (a) sibling
   directories under a common unbound version dir collapse to that version dir; (b) a version dir
   plus its own subdirectory collapse to the version dir; (c) a directory with no matching version
   segment is left unchanged; (d) a decoy segment with digits but no matching extracted value (e.g.
   `x86-64_linux26`) never becomes a stop point; (e) two directories differing only in a run of
   consecutive slashes (e.g. `rtla//X-2025.06-SP2` vs `rtla/X-2025.06-SP2`) merge into one entry
   with unioned flows.
10. **Unit — report rendering:** assert the missing-directories section is sorted/deduped with
    flow comments; the duplicate-toolversions section only lists `[TOOLVERSION]` keys with 2+
    distinct values, with correct counts; the reduction-summary section only lists groups that
    actually changed; `build_report` includes all four sections.
11. **Unit — incremental log:** assert the header is written before any flow runs and each flow's
    block is appended in order, independently readable after each append.
12. **Unit — global no-args call:** assert `default_global_cth_query_runner` invokes `cth_query
    -resolve` with no `-tool` flag, and that its result is processed like any flow (`flow=GLOBAL`,
    `activity=n/a`) feeding CSV/log/bindings_tools identically.
13. **Unit — generic-directory filter:** given the worked examples from §4 (`/p/hdk/cad/conformal`
    vs `.../conformal/25.20-p100`; `.../mentor/visualizer` vs `.../visualizer/w230217`;
    `/p/hdk/cad/mint/v25ww40`; `.../VisaIT/` vs `.../VisaIT/5.4`;
    `/p/hdk/rtl/proj_tools/vc_methodology_lint/master` vs `.../master/2.02.23.25ww19`;
    `/usr/intel/bin`), assert the depth rule is applied first and the EDA-tool-root
    version-basename rule only applies under the three specified roots.
14. **Unit — `--filter` regex file:** assert `"<regexp>"` lines parse correctly (comments/blanks
    ignored, malformed lines raise, patterns containing literal `/` compile and match without any
    unescaping); assert `re.search`/case-sensitive/OR matching drops directories and records a
    `--filter pattern matched: "..."` reason; assert a missing/unreadable `--filter` file is a
    pre-flight error.
15. **Unit — `--include` file:** assert blank lines are ignored and directories parse in file
    order; assert a new directory is appended tagged `--include` while a directory already present
    is skipped (not duplicated) but still reported; assert duplicate lines within the include file
    itself are only processed once; assert a missing/unreadable `--include` file, or any listed
    directory that doesn't exist/isn't readable, is a pre-flight error; assert `build_report`
    includes the new "Summary of directories added via --include" section.
16. **Unit — `--include` comment carry-over:** assert a comment line attaches only to the next
    directory (and resets afterward, so a later directory with no preceding comment gets none);
    assert comments accumulate across a blank line rather than resetting; assert multiple
    consecutive comment lines are preserved as separate lines, in order; assert
    `render_addition_block` renders them after `# Registered by flows: --include` and before the
    directory's list item.
17. **Unit — already-in-original-yaml filter:** given a fixture yaml with quoted, unquoted, and
    Singularity `src:dest` bindings_tools entries (plus a `bindings_design:` entry that must NOT
    leak in), assert `parse_existing_bindings_tools` extracts only the normalized source paths
    from `bindings_tools:`; assert `filter_existing_in_yaml` drops matching candidates and keeps
    genuinely new ones.
18. **Unit — counts summary:** assert `render_counts_section` renders all seven metrics plus the
    `Output yaml:` path line, in order, matching the labels defined in §4; assert `build_report`
    puts this section first.
19. **Smoke (manual/opt-in):** run against a real Cheetah shell and activity mapping, diff the
    `.raw`/`.final` yaml against a known-good container build result.

If you want to run any tests outside of a Cheetah shell,  you can do the following:
- Capture the environment before running the Cheetah shell
- Capture the environment after running the Cheetah shell
- Compare the two environments and extract the differences
- Save the differences to a file called `cthbind.env.diff`
- Use the `cthbind.env.diff` file to set the environment variables before running the tests.  This will allow you to run the tests outside of a Cheetah shell.

---

## 8. Implementation plan (phased)

- For every phase of implementation,  
  - Write unit tests for the new functionality.
  - Implement the new functionality.
  - Run unit tests to verify the new functionality works as expected.
  - Update the implementation plan with any changes or new phases.
  - Update a README.cthbind.md file with the new functionality and how to use it.
  - Always update the spec (this document) in a way which makes it useful as a template for future development.

**Phase 1 (done):** INI parsing, directory/PATH detection, dedup + comment generation, yaml
`bindings_tools:` insertion, activity mapping parsing, `cth_query` invocation with per-flow
failure handling, `.orig`/`.new`/`.csv`/`.log` output, CLI.

**Phase 2 (done, 2026-08-02):** `.new.reduced` output (version-floor directory reduction),
`.report` output (missing-directories / duplicate-toolversions / reduction-summary sections),
readable-directory bug fix (unresolved tokens and plain files no longer leak into bindings_tools),
incremental `.log` writes (header up front, per-flow appends), "Registered by flows" wording
everywhere, a single no-args `cth_query -resolve` global call (labeled `GLOBAL`/`n/a`) run once
before the per-flow loop to capture `[LITEINFRA]`, `:=` accepted alongside `=` as the key/value
separator when parsing `cth_query` output, multi-slash normalization during `.new.reduced`
construction, and a post-reduction generic-directory filter (depth + EDA-tool-root
version-basename rules, including `/p/hdk/rtl/proj_tools/`) with its own `.report` section, and
an optional `--filter <path>` CLI option (user-supplied exclusion list applied last,
`.new.reduced` only; originally `/regexp/` slash-delimited — see Phase 3).

**Phase 3 (done, 2026-08-03):** `--filter <path>` CLI option changed to `"<regexp>"`
double-quote-delimited lines (was `/<regexp>/` slash-delimited); new `--include <path>` CLI
option to force extra directories into `.new.reduced` (pre-flight-validated, processed last,
after reduction and all filtering, tagged `# Registered by flows: --include`); new `.report`
section "Summary of directories added via --include"; new already-in-original-yaml filter rule
(`.new.reduced` only) that drops candidates already listed in the input yaml's `bindings_tools:`
section (Singularity `src:dest` aware), reported in the existing "Summary of directories filtered
from .reduced" section; `--include` now also carries `#` comment lines from the include file
through to `.new.reduced` as context (attached to the next directory only, rendered after the
`--include` flows line and before the directory's list item; `BindingEntry` gained a `comments`
field for this).

**Phase 4 (done, 2026-08-04):** output files renamed for clarity — `.new` → `.raw` (the full,
unfiltered extraction) and `.new.reduced` → `.final` (grouped, filtered, +includes — the file
meant for actual use); every log/report/CLI-help/spec/README reference updated to match. New
`.report` "Summary of counts" section (leads the file, before all other sections): 7 metrics —
found (deduplicated) → found-readable → grouped → after-filtering → include-total →
include-readable → final-total — plus the resolved `.final` path, giving an at-a-glance funnel
view of the whole run. New `RunCounts` dataclass + `render_counts_section()`; `build_report()`
gained a leading `counts` parameter.

**Phase 5 (not started):** none currently planned; revisit non-goals in §9 if new requirements arrive.

---

## 9. Non-goals (for now)
