# Spec: `compare_pprtl2` — cross-run comparison / trend analysis of PPRTL2 report data

<!--
=============================================================================
REUSABLE AUTOMATION-WORKFLOW SPEC TEMPLATE
Copy this file to <project>/<tool>.spec.md and fill in each section.
Completed, real-world examples:
  - scripts/pprtl2/prep_pprtl2.spec.md
  - scripts/ctech/prep-tech/prep_tech.spec.md   (inputs, token/indirection
    resolution with on-disk fallback, optional per-line modifiers, precedence,
    report header + STDOUT parity, report-only anomaly detection)
  - scripts/pprtl2/report_pprtl2.spec.md   (report-only tool over an EXISTING run
    area written by another tool/flow: dual on-disk layouts that can coexist
    per-item in the same workarea, a fixed-width/box-drawing report format that
    looks like key=value but isn't, precedence between a summarized report and
    its raw per-metric sources, "every target item must appear in the output even
    if it never ran" completeness guarantee, and grep-with-context-window
    failure triage. See §6 for the full list of verified-on-disk corrections.)
  - scripts/pprtl2/compare_pprtl2.spec.md   (THIS doc: a second-order tool whose
    inputs are ANOTHER tool's CSV outputs across N workareas -- dynamic metric
    derivation from the source header minus an exclusion list, a display-value vs.
    numeric-backing-value split for human-formatted columns (durations, "12.63 GB"),
    a compare key that had to be widened after real data disproved the assumed one,
    and union-of-keys coverage across runs.)

How to use:
  1. Work top-down. Nail Purpose + Inputs + Outputs before anything else.
  2. Keep a running Decisions log (§6): every clarifying Q&A and every
     "flag only" Note. This is what makes the spec re-ingestable after edits.
  3. VERIFY inputs/outputs against real data on disk before coding — record
     the verified facts inline ("Verified on disk (date): ...").
  4. Deliver in phases (§8) with tests per phase; update Status as you go.
  5. Delete these comment blocks and the checklists you don't need.
=============================================================================
-->

Status: **DONE** — phases 1-3 plus enhancements E1 (§3.5), E2 (§3.6) and E3 (§3.7)
  complete, 86 unit tests pass, and smoke-tested end-to-end against two real
  workareas. Re-verified 2026-08-14 against the renamed `report_pprtl2` qor
  columns (§6 Q14): no code change needed, fixtures and §2.3/§3.2 refreshed.
  See §8 for phase-by-phase results and §6 for every verified-on-disk correction
  to this doc's original assumptions.
Owner: mroha
Language: Python 3 (driver)
Scope: Combine and summarize data from multiple PPRTL runs. Purpose is to spot change trends in power analysis results over time,  models,  and possibly tool versions.  Will be using the existing report_pprtl2 outputs as the primary data source.
Implementation: scripts/pprtl2/compare_pprtl2.py (+ scripts/pprtl2/test_compare_pprtl2.py)

---

## 1. Purpose

This tool accepts an ordered list of model→PPRTL2-workarea pairs and generates
comparative reports highlighting changes and trends across those runs.

It reads the outputs of the `report_pprtl2` tool (`report_pprtl2.qor.csv` and
`report_pprtl2.compute.csv`) as its primary — and only — data source. It never
re-derives metrics from the raw run area; if a number is wrong, the fix belongs in
`report_pprtl2`, not here.

Guaranteed properties:

- **Generative & idempotent:** re-running reproduces the same output files from the
  same inputs.
- **Non-destructive to sources:** it does not modify its inputs (neither the models
  `.md` file nor any workarea).

---

## 2. Inputs (sources of truth)

The user-configured input is a list of model names and directories, one
model\u21a6directory pair per line, in a `.md` file. Each directory is a PPRTL2
workarea that must contain the `report_pprtl2` CSV outputs under `power/pprtl2/`.

| # | Source | Provides | Notes (exact paths, selection rules, gotchas) |
|---|--------|----------|-----------------------------------------------|
| S1 | `<models.md>` (via `--models-for-compare`) | Ordered list of model\u21a6workarea pairs | `<model> = <workarea>`; see §2.2. First entry is the **baseline**. |
| S2 | `<workarea>` | A PPRTL2 run workarea | Must contain the `power/pprtl2/` subdirectory written by `prep_pprtl2`/`report_pprtl2`. |
| S3 | `<workarea>/power/pprtl2/report_pprtl2.compute.csv` | Per-run compute metrics (runtime, memory, cell count) | Header row + data rows. See §2.3. |
| S4 | `<workarea>/power/pprtl2/report_pprtl2.qor.csv` | Per-run QoR metrics (clock gating, cell/bit counts, annotations) | Header row + data rows. See §2.3. |

**Verified on disk (2026-08-12)** against the two workareas named in the user's
example `compare_pprtl2.models.md`:

- `26ww27a` = `/nfs/site/disks/corimhoks_rtl_h2b_011/mroha/dmrhub2-a0-corioh-pprtl2-partitions-b`
- `26ww32d` = `/nfs/site/disks/corimhoks_rtl_h2b_011/mroha/dmrhub2-a0-corioh-pprtl2-partitions-c`

Both contain `power/pprtl2/report_pprtl2.{compute,qor}.csv` (plus
`report_pprtl2.fail.details`, which this tool ignores). Each CSV has 1 header +
296 data rows covering 146 unique modules. The two runs' key sets are **identical**
(`diff` of the sorted key columns is empty) \u2014 but the tool must not assume that
(§3.1 union rule).

### 2.1 Pre-flight validation (fail fast)

Validate everything below **before writing any output**. Any failure \u21d2 error
message on STDERR + exit code 2, nothing written.

**Checks:**
- `--models-for-compare` file exists and is readable.
- At least **two** model\u21a6workarea pairs parse out of it (a comparison of one run is
  meaningless).
- Model names are unique (a duplicate would produce duplicate output columns).
- No model name contains a comma or a double quote (it becomes a CSV header field).
- Each workarea directory exists and is a directory.
- `report_pprtl2.compute.csv` and `report_pprtl2.qor.csv` exist and are readable
  under `<workarea>/power/pprtl2/` in **every** workarea.
- Each CSV has a header row containing all four key columns
  (`module`, `power_mode`, `test_name`, `instance`).
- **Key uniqueness:** within any single CSV, the compare key
  (`module`+`power_mode`+`test_name`+`instance`, after the §2.3 normalization) must
  appear at most once. A duplicate is a hard error naming the file and the key.
- `--outdir`, if given, exists and is a directory (**not** created \u2014 see §6 Q9).

### 2.2 Input model-directory.md

Example (`/nfs/site/disks/xpg_dmrhub2_0053/mroha/corpower/scripts/pprtl2/compare_pprtl2.models.md`,
verified on disk 2026-08-12):

```md
# compare_pprtl2 input model list
# format is <model>=<workarea>

26ww27a=/nfs/site/disks/corimhoks_rtl_h2b_011/mroha/dmrhub2-a0-corioh-pprtl2-partitions-b
26ww32d=/nfs/site/disks/corimhoks_rtl_h2b_011/mroha/dmrhub2-a0-corioh-pprtl2-partitions-c
```

Parsing rules, in order:

1. Skip blank lines and lines whose first non-whitespace character is `#`.
2. Match the remaining lines against `^\s*(\S+)\s*=\s*(\S+)(\s+.*)?$` \u2014
   group 1 = model name, group 2 = workarea, group 3 = ignored trailing text.
3. A non-blank, non-comment line that does **not** match is an error (do not
   silently skip it \u2014 a typo'd path must not vanish).
4. **Order is preserved.** The first pair is the **baseline** model; every other
   model is compared against it (never against its predecessor \u2014 §6 Q6).

### 2.3 Input .csv files

Both source CSVs share the same first four columns, which together form the
**compare key**:

```
module, power_mode, test_name, instance
```

Verified headers (2026-08-12, identical in both workareas):

```csv
# report_pprtl2.compute.csv
module,power_mode,test_name,instance,elab_run_status,fsdb_run_status,power_run_status,
cell_count,elab_runtime,elab_runtime_seconds,fsdb_runtime,fsdb_runtime_seconds,
power_runtime,power_runtime_seconds,total_runtime,total_runtime_seconds,
elab_peak_memory,fsdb_peak_memory,power_peak_memory

# report_pprtl2.qor.csv    (re-verified 2026-08-14 — see §6 Q14 for the rename)
module,power_mode,test_name,instance,elab_run_status,fsdb_run_status,power_run_status,
untraced_sequentials_percentage,annotation_primary_io,annotation_bb,annotation_seq,
CGR,CGE,DACGE,
cell_count,combinational_cell_count,unclocked_sequential_cell_count,
register_cell_count,register_bit_count,
flop_cell_count,mbflop_cell_count,eqfb,latch_cell_count,mblatch_cell_count,eqlb,
VCS_VERSION,VERDI_VERSION,PPRTL_VERSION
```

Reading rules:

- Parse with `csv.DictReader` (values may be quoted; do not `str.split(",")`).
- Lines whose first non-whitespace character is `#` are comments and are skipped.
  (Verified: the current `report_pprtl2` emits **zero** comment lines, but the
  reader must tolerate them.)
- Strip surrounding whitespace from every field.
- **Normalization:** a blank `test_name` on a **vectorless** row is read as
  `default`. A blank `test_name` on a **timebased** row stays blank \u2014 see §6 Q10.
- `instance` is legitimately blank for vectorless rows; that blank is part of the key.

Example key with two instances (verified, workarea `-b`) \u2014 this is why `instance`
is in the key:

```csv
parscfllcsftype3,vectorless,default,,...
parscfllcsftype3,timebased,active_idle,parllcsf_a_parscfllcsftype3,...
parscfllcsftype3,timebased,active_idle,parllcsf_a_parscfllcsftype4,...
```

---

## 3. Outputs (the generated tree)

Output root is the current working directory, or `--outdir <path>` if given
(§6 Q4/Q9 — the directory must already exist; it is never created).

```
<output_root>/
├── compare_pprtl2.qor.csv       # from every workarea's S4  (§3.2)
├── compare_pprtl2.compute.csv   # from every workarea's S3  (§3.3)
└── compare_pprtl2.status.csv    # from every workarea's S4  (§3.6)
```

All three files are regenerated (overwritten) on every run.

## 3.1 Shared row/column model

All output CSVs use the same shape. For `N` models `m1` (baseline), `m2` … `mN`:

```csv
module,power_mode,test_name,instance,metric,<m1>,…,<mN>,<baseline comparisons…>,<chained comparisons…>
```

The comparison columns are described in §3.7; `compare_pprtl2.qor.csv` and
`compare_pprtl2.compute.csv` express them as `% diff`, `compare_pprtl2.status.csv`
as `change` (§3.6).

- One row per **(compare key × metric)**.
- **Key coverage = union** of the compare keys across all models. A key present in
  only one model still gets rows; the other models' cells are blank.
- **Metric set = union**, in first-seen header order, of each model's CSV columns
  after removing the four key columns and the per-file exclusion list (§3.2, §3.3).
  Derived dynamically so that new `report_pprtl2` columns appear automatically
  (§6 Q8); a column missing from one model's CSV simply yields blank cells there.
  `compare_pprtl2.status.csv` is the exception: it uses a fixed **inclusion** list
  (§3.6), because its columns are deliberately the ones the other two exclude.
- **Row order:** sorted by `module`, `power_mode`, `test_name`, `instance`, then by
  metric in the derived metric order (i.e. all metrics of one key are adjacent).
- **Value cells** hold the source CSV value **verbatim** (including human-formatted
  strings like `00d:00h:32m:14s` and `12.63 GB`) — except where §3.5 replaces them
  with a run status.
- **`% diff` cells** are computed from the *numeric backing value* of the metric
  (§3.4), as `round((value − reference) / reference × 100, 2)`, where the reference
  is the baseline or the chain neighbour depending on the column (§3.7).
- A `% diff` cell is **blank** when any of the following hold:
  - the reference model has no row for this key, or a blank/non-numeric value;
  - the reference numeric backing value is `0` (no division by zero — §6 Q5);
  - the compared model has no row for this key, or a blank/non-numeric value;
  - either side is showing a run status instead of a number (§3.5).
- Negative values are emitted with a leading `-`; no `+` prefix on positives.
- The header is always written, even if there are zero data rows.

## 3.2 compare_pprtl2.qor.csv

Excluded source columns (never become metric rows):

```
elab_run_status, fsdb_run_status, power_run_status          # non-numeric status
VCS_VERSION, VERDI_VERSION, PPRTL_VERSION                   # non-numeric tool versions
```

Resulting metric rows, in header order (**18** as of 2026-08-14):

```
untraced_sequentials_percentage, annotation_primary_io, annotation_bb, annotation_seq,
CGR, CGE, DACGE,
cell_count, combinational_cell_count, unclocked_sequential_cell_count,
register_cell_count, register_bit_count, flop_cell_count, mbflop_cell_count, eqfb,
latch_cell_count, mblatch_cell_count, eqlb
```

All of these are plain numerics; the value cell *is* the numeric backing value.

This list is *the current expected result*, not a contract — it is derived from the
header at run time (§6 Q8), which is exactly why the 2026-08-14 `report_pprtl2`
rename and the new `combinational_cell_count` needed **no code change** (§6 Q14).

Example:

```csv
module,power_mode,test_name,instance,metric,26ww27a,26ww32d,26ww32d vs 26ww27a % diff
paraccchassis,timebased,active_idle,paraccchassis_paraccchassis,CGR,97.35,96.10,-1.28
paraccchassis,timebased,active_idle,paraccchassis_paraccchassis,CGE,81.42,81.42,0.00
paraccchassis,vectorless,default,,CGR,97.35,,
```

## 3.3 compare_pprtl2.compute.csv

Excluded source columns:

```
elab_run_status, fsdb_run_status, power_run_status          # non-numeric status
elab_runtime_seconds, fsdb_runtime_seconds,
power_runtime_seconds, total_runtime_seconds                # backing values only
```

Resulting metric rows, in header order:

```
cell_count
elab_runtime, fsdb_runtime, power_runtime, total_runtime
elab_peak_memory, fsdb_peak_memory, power_peak_memory
```

The `*_runtime` rows display the human-readable duration and compute their `% diff`
from the corresponding `*_runtime_seconds` column (§3.4). The `*_peak_memory` rows
display the human-readable size and compute their `% diff` from the unit-normalized
value (§3.4).

Example:

```csv
module,power_mode,test_name,instance,metric,26ww27a,26ww32d,26ww32d vs 26ww27a % diff
paraccasf,timebased,active_idle,paraccasf_paraccasf,cell_count,95549,96000,0.47
paraccasf,timebased,active_idle,paraccasf_paraccasf,elab_runtime,00d:00h:32m:14s,00d:00h:35m:00s,8.58
paraccasf,timebased,active_idle,paraccasf_paraccasf,elab_peak_memory,12.63 GB,13.10 GB,3.72
```

## 3.4 Numeric backing values (display vs. compute)

| Metric shape | Displayed | Used for `% diff` |
|---|---|---|
| Plain numeric (`cell_count`, `CGR`, …) | source value | `float(value)` |
| `<x>_runtime` (`00d:02h:35m:56s`) | source value | the sibling `<x>_runtime_seconds` column (`9356.0`) |
| `*_peak_memory` (`12.63 GB`) | source value | unit-normalized float (below) |

Memory normalization: parse `^\s*([0-9.]+)\s*([KMGT]?B)\s*$` case-insensitively and
scale to a common unit using **decimal (1000-based)** factors — `KB=1e3`, `MB=1e6`,
`GB=1e9`, `TB=1e12`, matching `report_pprtl2`'s own `mem_gb = mem_mb / 1000`
convention. Unparseable ⇒ treated as non-numeric ⇒ blank `% diff`.
(Verified 2026-08-12: every memory value in both workareas is `GB`; the other units
are supported defensively per §6 Q3.)

Any value that fails `float()` (or the shape-specific parse above) is
**non-numeric**: it is still displayed, but its `% diff` is blank.

---

## 3.5 Non-passing power runs report their status

When a power run does not pass, `report_pprtl2` leaves the metric columns blank
**or**, worse, emits bogus numbers from a partially-written report (real example:
`CGR=0`, `flop_cell_count=0`, `register_cell_count=0`). Both are misleading in a
trend report — a bogus `0` against a healthy baseline renders as `-100.00%`.

Rule: for a given (key, model), if that model's **`power_run_status` is not
`Pass`**, every metric **value column** for that key/model shows the status string
instead of the source value, and **no `% diff` is computed** for any pair
involving it (the diff cell is blank).

- **Only `power_run_status` is consulted.** `elab_run_status` and
  `fsdb_run_status` are ignored entirely (Q11).
- **The exit code is stripped**: `Fail=2` ⇒ `Fail`. Other statuses appear
  verbatim: `Not Started`, `Running`.
- **All metrics for that key/model are replaced**, including stages that really
  did run (e.g. `elab_runtime`, `elab_peak_memory`). Trading that detail away is
  deliberate: the row is about a failed power result and must not invite
  comparison (Q11).
- **The trigger is the status column only, never the value.** Legitimate zeros on
  passing runs are preserved — verified: `bb_annotation=0` on 32 passing modules,
  plus `CGR`/`mbflop_cell_count`/`latch_cell_count`/`eqlb` zeros on passing rows.
- `Not Required` never appears in `power_run_status` (it is an fsdb-only state),
  so `!= Pass` is the whole rule.
- Only the failing model's column changes; sibling models keep their real values.
- A key absent from a model still yields a blank value, not a status.

---

## 3.6 compare_pprtl2.status.csv (run status & tool versions)

The other two files deliberately exclude the status and version columns because a
`% diff` of `Pass` or `X-2025.06-SP2-3` is meaningless. This file is where they
are compared instead, using the same row/column model (§3.1) with `same`/`changed`
in place of `% diff`.

**Source: `report_pprtl2.qor.csv` only.** Verified 2026-08-13: the three status
columns are byte-identical between the compute and qor CSVs for **all 296 keys in
both workareas**, and the three version columns exist **only** in qor. So one file
supplies everything and no cross-file merge is needed.

**Items (a fixed inclusion list, in this order):**

```
elab_run_status, fsdb_run_status, power_run_status
VCS_VERSION, VERDI_VERSION, PPRTL_VERSION
```

This is an *inclusion* list, the mirror image of §3.2's exclusion list, so the two
stay in sync by construction. An item missing from every model's header is
dropped rather than emitted as an all-blank row.

**Comparison cells** (one per comparison column of §3.7):

| Condition | Cell |
|---|---|
| Both models have the key and the values match after stripping | `same` |
| Both models have the key and the values differ | `changed` |
| Either model lacks the key | *blank* |

Notes:

- **Statuses appear verbatim here, including the exit code** (`Fail=2`), unlike
  §3.5's value substitution which strips it. This file is the detail view, so the
  code is worth keeping; the metric files only need "don't trust this number".
- **§3.5 does not apply to this file.** A failed power run must still show its real
  status and its real tool versions here, otherwise the report would hide exactly
  what it exists to show.
- Versions are per-workarea constants in practice (one value across all 296 rows,
  identical in both current workareas), but they are still emitted **per key** so
  the file stays uniform and would reveal a workarea built with mixed tool
  versions (§6 Q12).
- Every key is listed, not only the changed ones (§6 Q12), so the file can be
  diffed and joined like the other two.

Row count: `|union keys| × 6`. For the current workareas: `296 × 6 = 1776`.

---

## 3.7 Comparison columns: baseline block, then chained block

Model order in the models file (S1) is significant twice over: `m1` is the
baseline, and the listed order is also the **chain order**.

For `N` models the comparison columns are, in order:

1. **Baseline block** — `m2 vs m1`, `m3 vs m1`, … `mN vs m1`.
2. **Chained block** — `m3 vs m2`, `m4 vs m3`, … `mN vs m(N−1)`.

The chain's first link (`m2 vs m1`) *is* the first baseline comparison, so it is
**not repeated** (§6 Q13). Consequences:

- `N = 2` → one column, exactly as before this enhancement. Two-model runs are
  completely unchanged.
- `N = 3` → `m2 vs m1`, `m3 vs m1`, `m3 vs m2` — chaining adds one column.
- Column count is `2N − 3` for `N ≥ 2`.

Both blocks use the same suffix per file: `% diff` for the metric files, `change`
for the status file. Example 4-model qor header tail:

```csv
…,metric,m1,m2,m3,m4,m2 vs m1 % diff,m3 vs m1 % diff,m4 vs m1 % diff,m3 vs m2 % diff,m4 vs m3 % diff
```

Chained cells follow exactly the same blanking rules as baseline cells (§3.1),
with the neighbour as the reference instead of the baseline.

---

## 4. Per-item derivation rules

Per run, in order:

1. Parse S1; establish model order, the baseline **and the chain order** (§3.7).
2. Pre-flight (§2.1).
3. For each model, load S3 and S4 into `{key: {column: value}}` maps.
4. Build the union key set and the derived metric list per output file (§3.1).
5. Emit all three CSVs, overwriting any prior copy.

**Reports** (write these every run, overwriting prior copies): all three files in
§3. There is no incremental/append mode.

---

## 5. CLI

```
compare_pprtl2.py \
  --models-for-compare <model-workarea md file>   # required
  [--outdir <path>]                               # default: CWD; must already exist
  [--dry-run] [--force] [--verbose]
```

Conventions (recommended for all automation):
- `--dry-run` — print the plan (every planned output path, the resolved model
  order, key/metric counts), write nothing.
- `--force` — for TREE-GENERATING tools (e.g. prep_pprtl2): overwrite existing
  outputs; default **skips** existing (idempotent). For a pure REPORT-generating
  tool like this one, all output files are always regenerated/overwritten every
  run (per §4) since they're cheap to rebuild and must reflect current state --
  `--force` is accepted for CLI parity but is a no-op here.
- `--verbose` — log each file written and each per-model CSV loaded (with row counts).
- Exit codes: `0` success, `2` pre-flight/usage error.
- Validate all inputs before writing any output (fail fast).

---

## 6. Decisions log (resolved questions & notes)

Verified-on-disk corrections to this doc's original draft (2026-08-12):

- **V1 — the assumed compare key was wrong.** The draft's
  `module+power_mode+test_name` is **not** unique on real data: 4 keys in *each* of
  the two sample workareas have two `instance` values (e.g. `parscfllcsftype3` /
  `timebased` / `active_idle` × `parllcsf_a_parscfllcsftype3` and
  `parllcsf_a_parscfllcsftype4`). §2.1's uniqueness pre-flight would have failed on
  every real run. Key widened to include `instance`, which is unique (0 duplicates
  in both files).
- **V2 — the source CSVs contain no `#` comments.** The draft said pound signs are
  used for comments; zero comment lines exist in either file today. Support is kept
  as defensive tolerance only, not a documented input format.
- **V3 — memory values are all `GB`** in both workareas (441 and 444 occurrences
  respectively, no `MB`/`KB`), but unit handling is still required (Q3).
- **V4 — blank `test_name` occurs on `timebased` rows, not vectorless.** Both
  workareas contain exactly two such rows (`parmiopcie6trcore_uio_0` and `_1`, both
  `timebased,,` with `fsdb_run_status=Running`) — these are `report_pprtl2`'s
  "no test directory yet" fallback rows. See Q10.

Clarifying Q&A (2026-08-12):

- **Q1 — Compare key.** *Add `instance`?* → **Yes.** Key is
  `module+power_mode+test_name+instance`, and `instance` becomes a 4th key column
  in both output CSVs.
- **Q2 — Non-numeric columns.** *How handled?* → **Omit them** from the two metric
  files. *(Superseded in part by Q12: they are no longer dropped outright — they
  moved to `compare_pprtl2.status.csv`, which compares them as `same`/`changed`.)*
  - qor: drop `elab_run_status`, `fsdb_run_status`, `power_run_status`,
    `VCS_VERSION`, `VERDI_VERSION`, `PPRTL_VERSION`.
  - compute: drop the three `*_run_status` columns and the `*_runtime_seconds`
    columns; keep the human-readable `*_runtime` values as the displayed value but
    still compute a real `% diff` for them from the seconds columns.
    `total_runtime_seconds` is likewise available as a backing value (compute only).
- **Q3 — Memory.** *Parse or treat as string?* → **Numeric, with the `KB`/`MB`/`GB`
  suffix as the scale qualifier.** Display the original string; normalize for math.
- **Q4 — Output location.** → **CWD by default, `--outdir <path>` to override.**
  (Not the baseline workarea, and not `$WORKAREA` — a comparison spans N workareas,
  so no single workarea is the natural owner. This supersedes the draft's
  "`<workarea>/power/pprtl2`" output root.)
- **Q5 — Coverage & division by zero.** → **Union of all keys across all models**;
  a row is emitted even when the baseline lacks it. `% diff` is blank whenever the
  baseline value is missing, blank, non-numeric, or zero.
- **Q6 — Header naming / N models.** → Exactly as §3.1. Every non-baseline model
  gets exactly one `<model> vs <baseline> % diff` column. *(Superseded by Q13:
  those baseline columns are still all present and unchanged, but a chained block
  is now appended after them — see §3.7.)*
- **Q7 — Extra outputs.** *Threshold-filtered report? summary.md?* → **No.** Both
  remain non-goals (§9). *(The status/version file added by Q12 is a third CSV, not
  a summary: it lists every key and applies no threshold.)*
- **Q8 — Metric list hardcoded or derived?** → **Derived** from the CSV header
  minus the key columns minus an explicit exclusion list, so new `report_pprtl2`
  columns flow through without a code change. The §3.2/§3.3 metric lists are
  therefore *the current expected result*, not a hardcoded contract.
- **Q9 — `--outdir` creation.** → **Do not create it.** A missing `--outdir` is a
  pre-flight error. (The CWD default always exists.)
- **Q10 — Blank `test_name`.** The draft said to read a blank `test_name` as
  `default`. Scoped to **vectorless rows only**: the current `report_pprtl2` already
  writes `default` for vectorless, so this only matters for older CSVs. Timebased
  rows with a blank `test_name` are the real "no test directory yet" fallback rows
  (V4) and must keep the blank — renaming them `default` would merge them with
  unrelated keys.
- **Q11 — Non-passing power runs (enhancement, 2026-08-12).** Failed/incomplete
  power runs were surfacing as blanks *or* bogus `0`s, and a bogus `0` against a
  healthy baseline renders as a scary, meaningless `-100.00%`. Resolved: show the
  **`power_run_status`** string in the value columns and suppress the `% diff`
  (§3.5). Three sub-decisions, all confirmed with the user:
  - *Scope*: **all** metrics of that key/model, not just the power-derived ones —
    even though `elab_runtime`/`elab_peak_memory`/`total_runtime` are verified to
    hold **real** values on failing rows (100% populated, 0 blanks). The row is
    about a failed power result and should not invite comparison.
  - *Which status*: **`power_run_status` only**; `elab_run_status` and
    `fsdb_run_status` are ignored. This also makes `Not Required` irrelevant, as
    it only ever appears in `fsdb_run_status` (146/296 rows, the normal vectorless
    state), so the rule reduces to `!= Pass`.
  - *Format*: strip the exit code — `Fail=2` ⇒ `Fail`; `Not Started` / `Running`
    verbatim.
- **Q12 — Status/version report (enhancement, 2026-08-13).** Added as a third file
  rather than as columns in the existing two, because its comparison cells are
  `same`/`changed` rather than numeric. Decisions: name it
  `compare_pprtl2.status.csv`; one row **per key** for versions too (not once per
  run) so the layout is uniform and mixed-version workareas would be visible;
  **all** keys listed, not just changed ones; `same`/`changed` indicator columns
  rather than transition text like `Pass -> Fail=2`.
- **Q13 — Chained deltas (enhancement, 2026-08-13).** Models-file order is the
  chain order. The chained columns are appended **after** the full baseline block,
  and the duplicate first link (`m2 vs m1`, which is both the first chain link and
  the first baseline comparison) is **omitted** rather than emitted twice. Always
  on — no CLI flag — since a 2-model run produces no chained columns at all and is
  therefore bit-identical to the pre-enhancement output.
- **Q14 — Upstream qor column rename (2026-08-14).** `report_pprtl2` renamed five
  qor columns and added one; `compare_pprtl2` needed **no code change** and ran
  clean (exit 0) on the regenerated workareas, which is the payoff for deriving
  the metric list rather than hardcoding it (Q8).

  | Was | Now |
  |---|---|
  | `untraced_sequentials` | `untraced_sequentials_percentage` |
  | `primary_io_annotation` | `annotation_primary_io` |
  | `bb_annotation` | `annotation_bb` |
  | `seq_annotation` | `annotation_seq` |
  | `sequential_cell_count` | `unclocked_sequential_cell_count` |
  | *(new)* | `combinational_cell_count` |

  qor metrics went 17 → 18, so the qor report went 5032 → 5328 rows. The compute
  header was unchanged. Only the **fixtures and this document** needed updating.

  **Caveat — mixed-vintage comparisons.** Because the metric set is a *union*
  (§3.1), comparing a pre-rename workarea against a post-rename one is not an
  error and loses no data, but it emits **both** spellings as separate,
  half-populated metrics. Measured on a reconstructed old-format workarea:
  23 metrics instead of 18, of which 10 are blank on one side. Re-run
  `report_pprtl2` on every workarea in the models file before comparing across
  this boundary. This is inherent to the union rule and is deliberately not
  "fixed" with a rename map — an alias table would silently equate columns whose
  definitions may also have changed.

---

## 7. Test plan

`scripts/pprtl2/test_compare_pprtl2.py`, run via
`python3 -m unittest test_compare_pprtl2 -v` from `scripts/pprtl2/`. No live tools,
no real workareas — every test builds its CSVs from fixtures in a
`tempfile.TemporaryDirectory`.

1. **`TestReadModelsFile`** — comment/blank-line skipping; the exact
   `<model> = <workarea>` pattern incl. surrounding whitespace and ignored trailing
   text; order preservation; malformed line ⇒ error; `<2` pairs ⇒ error; duplicate
   model name ⇒ error; comma in a model name ⇒ error.
2. **`TestPreflight`** — every failure mode from §2.1 exercised individually:
   missing models file, missing workarea, missing compute/qor CSV, header missing a
   key column, duplicate compare key within one CSV, missing `--outdir`.
3. **`TestMetricDerivation`** — key columns and the per-file exclusion lists are
   removed; header order preserved; a column present in only one model's CSV still
   becomes a metric (union) and is blank for the others; the §3.2/§3.3 lists are
   reproduced exactly from the real headers of §2.3.
4. **`TestNumericBacking`** — plain numerics; `<x>_runtime` uses
   `<x>_runtime_seconds`; memory unit scaling across `KB`/`MB`/`GB`/`TB` with the
   1000-based factors; unparseable memory ⇒ non-numeric; empty string ⇒ non-numeric.
5. **`TestPercentDiff`** — positive/negative/zero change rounded to 2 decimals;
   blank on missing baseline row, blank baseline value, non-numeric baseline,
   baseline `0`, and missing/blank/non-numeric compared value.
6. **`TestBuildRows`** — union key coverage (a key present only in the non-baseline
   model still produces rows); sort order; vectorless blank `test_name` → `default`
   while timebased blank stays blank (Q10/V4); a 3-model case proving every `% diff`
   column is computed against the baseline, not the previous model.
7. **`TestGenerateReportsAndCli`** — every file written with the §3.1 header; header
   emitted even with zero data rows; `--dry-run` writes nothing and still exits 0;
   `--force` changes nothing; exit codes 0 and 2; re-running produces
   byte-identical output (idempotence).
8. **`TestStatusLabel` / `TestFailedRunSubstitution`** — §3.5: `Pass`, blank and
   missing rows produce no label; `Fail=2` ⇒ `Fail`; `Not Started`/`Running`
   verbatim; failing model shows the status with a blank `% diff`; bogus `0`s *and*
   blanks from a failed run are both replaced; a legitimate `0` on a passing run is
   preserved; a failing **baseline** suppresses the diff for a passing model; every
   metric of a failed key is replaced incl. real elab data; a failed
   `elab_run_status`/`fsdb_run_status` changes nothing; in a 3-model run only the
   failing model's column is affected.
9. **`TestComparisonPairs`** — §3.7: 2 models ⇒ the baseline pair only; chained
   pairs start at the third model; across 2–7 models the pair list has no
   duplicates and its length is exactly `2N − 3`. Plus, in `TestBuildTable`: the
   3-model header shows the baseline block then the chained block, a 2-model run
   gains no chained column, chained cells compare against the neighbour
   (`100,200,400` ⇒ `100.00,300.00,100.00`), and a 4-model run proves the chain
   follows models-file order.
10. **`TestStatusReport` / `TestStatusTable`** — §3.6: the kind reads qor and writes
    `compare_pprtl2.status.csv`; `match_indicator` returns `same`/`changed`,
    ignores surrounding whitespace, and is blank when either row is missing; the
    item list is the 3 statuses then the 3 versions; the header uses `change`
    columns; identical runs are all `same`; a status change shows **verbatim with
    its exit code** (`Pass`, `Fail=2`, `changed`); a failed power run does **not**
    blank the version columns (§3.5 must not apply here); a tool upgrade shows
    `changed`; a key missing from one model gives a blank value and blank
    indicator; chained `change` columns track the neighbour.

**Smoke test (manual, not in CI):** run against the two real workareas via the
user's `compare_pprtl2.models.md`; spot-check that identical metrics yield `0.00`,
that the 4 multi-instance keys produce distinct rows, and that the row count equals
`|union keys| × |metrics|` for each file.

---

## 8. Delivery phases

- **Phase 1** — S1 parsing + pre-flight + CLI skeleton (`--dry-run` prints the
  resolved plan). Tests 1–2. Status: **DONE** (2026-08-12, 25 unit tests pass).
  CSV reading (`read_report_csv`) and key normalization (`row_key`) landed here
  rather than in phase 2, because pre-flight's header/duplicate-key checks need
  them. `read_report_csv` also tolerates ragged rows (short rows yield `None`,
  long rows a `list`, from `csv.DictReader`). Non-`--dry-run` runs currently
  print "report generation is not implemented yet" and exit 2.
  Smoke-tested against the two real workareas via the user's
  `compare_pprtl2.models.md`: pre-flight passes, which independently confirms V1
  (the `instance`-widened key is duplicate-free in all four real CSVs).
- **Phase 2** — metric derivation, numeric backing, `% diff`, row building.
  Tests 3–6. Status: **DONE** (2026-08-12, 49 unit tests pass). `ReportKind`
  (QOR/COMPUTE) carries each file's source/output name and exclusion list;
  `build_table()` returns a `CompareTable` (kind, header, metrics, keys, rows).
  `--dry-run` now reports the key/metric/row counts per §5.
  Verified against the two real workareas: 296 union keys, **17** qor metrics and
  **8** compute metrics — exactly the §3.2/§3.3 lists, derived not hardcoded.
  Spot-checked real diffs, e.g. `paraccchassis` `elab_runtime`
  `00d:00h:43m:10s` (2590s) → `00d:00h:38m:55s` (2335s) = `-9.85`, and
  `elab_peak_memory` `10.50 GB` → `10.45 GB` = `-0.48`.
- **Phase 3** — report writing, `--verbose`, idempotence; smoke test against the two
  real workareas. Test 7. Status: **DONE** (2026-08-12, 56 unit tests pass).
  New `write_table()`/`generate_reports()`; `main()` writes both CSVs and
  `--verbose` logs each path with its row count.
  Smoke test (`/tmp/cmp_smoke`, both real workareas): wrote
  `compare_pprtl2.qor.csv` (5032 rows + header) and `compare_pprtl2.compute.csv`
  (2368 rows + header); a second run was **byte-identical** (md5 verified).
  All three edge cases behaved as specified on real data:
  - the 4 multi-instance keys produced distinct rows
    (`parscfllcsftype3` × `parllcsf_a_parscfllcsftype3` and `...type4`, both
    `cell_count` `275081` → `275033` = `-0.02`);
  - `bb_annotation` `0.0` → `0.0` emitted a **blank** `% diff` (zero baseline);
  - the timebased blank-`test_name` key (`parmiopcie6trcore_uio_0,timebased,,`)
    survived as its own key, with a blank `cell_count` row but a real
    `elab_runtime` diff (`00d:16h:16m:32s` → `00d:14h:21m:27s` = `-11.78`).
- **Enhancement E1** — non-passing power runs report their status (§3.5, Q11).
  Test 8. Status: **DONE** (2026-08-12, 69 unit tests pass). Added
  `status_label()`; `build_table()` substitutes the label into the value columns
  and forces the backing value to `None` so no `% diff` is produced.
  Verified on the two real workareas: qor gained 272 `Fail`, 459 `Not Started`
  and 68 `Running` cells, compute 128/216/32, with **zero** rows carrying a status
  label alongside a non-blank `% diff`. Example asymmetric key
  (`parpsf0npktam,timebased,active_idle,parpsf0npktam_parpsf0npktam`): baseline
  `Not Started` across all 8 compute metrics while `26ww32d` shows its real
  numbers (`683245`, `00d:01h:13m:20s`, `24.54 GB`, …) and every diff is blank.
- **Enhancement E2** — status/tool-version report (§3.6, Q12). Test 10.
  Status: **DONE** (2026-08-13, 86 unit tests pass). `ReportKind` gained an
  `included` list and a `comparison` mode (`percent` | `match`); `STATUS` is a
  third kind reading qor and writing `compare_pprtl2.status.csv`.
  Verified on the two real workareas: `296 × 6 = 1776` rows; versions all `same`
  (both workareas ran identical tool versions); real status changes surfaced, e.g.
  `parmiofblprxfcrarbmux` `power_run_status` `Not Started` → `Pass` ⇒ `changed`.
- **Enhancement E3** — chained deltas (§3.7, Q13). Test 9.
  Status: **DONE** (2026-08-13, 86 unit tests pass). `comparison_pairs()` returns
  the baseline pairs then the chained pairs; `build_output_header()` and
  `build_table()` both drive off it, so the two blocks cannot drift apart.
  `--dry-run` now prints `Chain order: m1 -> m2 -> m3` for 3+ models.
  Verified with a 3-model run (third model deliberately pointed at the baseline's
  workarea): header ends
  `26ww32d vs 26ww27a % diff, 26ww35x vs 26ww27a % diff, 26ww35x vs 26ww32d % diff`,
  and `paraccchassis` `cell_count` `207916 / 253010 / 207916` yields
  `21.69 / 0.00 / -17.82` — the round trip is arithmetically consistent.
  All three files re-ran byte-identical (md5 verified), and a 2-model run still
  produces exactly one comparison column per file.

---

## 9. Non-goals

- **Re-deriving metrics from the raw run area.** This tool reads only
  `report_pprtl2`'s CSVs. Missing/incorrect metrics are a `report_pprtl2` issue.
- **Running `report_pprtl2`.** Each workarea's CSVs must already exist; the tool
  will not orchestrate or refresh them.
- **`report_pprtl2.fail.details` / `summary.md` comparison.** Only the two source
  CSVs are consumed.
- **Threshold-filtered "changed rows only" output** and an
  **improved/regressed/status-flipped summary** (Q7) — explicitly deferred.
- **Plots, charts, or HTML output.**

---

## Appendix A — Reusable engineering checklist

Patterns that repeatedly paid off (from the prep_pprtl2 / report_pprtl2 builds):

- [ ] **Deterministic + idempotent**: same inputs → same tree; safe to re-run.
- [ ] **Fail-fast pre-flight**: validate every input before writing anything.
- [ ] **Line-level modifiers + precedence**: support optional per-line flags; define
      how duplicates combine and which source wins when items collide.
- [ ] **Indirection / token resolution with fallbacks**: recursive substitution;
      discover on disk (disambiguated by a stable token) when the explicit form is
      absent; record the verified variants.
- [ ] **Report header + console/file parity**: tool name + run timestamp in the
      report; emit the same summary lines to STDOUT and the report top via one helper.
- [ ] **Report-only anomaly detection**: flag unresolved/undefined references without
      failing the run; scope the check to avoid false positives.
- [ ] **Per-item gating + report**: never fail the whole run for one bad item; record
      why each item was skipped/failed in a CSV + human summary.
- [ ] **Mutually-exclusive categories** that reconcile to the total.
- [ ] **Injectable subprocess runners** (default = real) so unit tests mock helpers —
      no live tools in CI.
- [ ] **Auto-detect over hardcode** where real layouts vary; use a profile map for
      known variants; expose CLI overrides for every profile field.
- [ ] **`--dry-run` / `--force` / `--verbose`** with idempotent-skip as the default.
- [ ] **NFS-safe file ops**: use `shutil.copytree(..., dirs_exist_ok=True)` for
      overlay copies; **avoid `rmtree` on trees that may hold open files** (leaves
      `.nfs*` artifacts + partially-deleted trees).
- [ ] **Pure path-derivation functions** (no disk access) → trivially unit-testable.
- [ ] **Verify against real data early**; record verified facts in the Decisions log.
      *(This spec's V1 is the canonical example: the assumed compare key was
      disproved by 4 real rows before a line of code was written.)*
- [ ] **Phased delivery** with tests per phase; keep Status current.
- [ ] **Note caveats honestly**: e.g. `--force` overwrites regenerated files but does
      not prune stale outputs from items that flipped to skipped/failed.
