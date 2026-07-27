# Spec: `<tool_name>` — <one-line purpose>

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

Status: **DONE** — Phases 1-4 complete and smoke-tested against 3 real workareas
  (2026-07-26). See §8 for phase-by-phase results and §6 for every verified-on-disk
  correction to this doc's original assumptions.
Owner: mroha
Language: Python 3 (driver)
Scope: Report generation for COR pprtl2 run area.  The run area can contain hundreds of individual power runs and these needs to be conveniently summarized and the data collated for analysis.
Implementation: scripts/pprtl2/report_pprtl2.py (+ scripts/pprtl2/test_report_pprtl2.py, 54 unit tests).

---

## 1. Purpose

This tool generates summary reports for the COR pprtl2 run area, providing both machine-readable and human-readable outputs. It is intended for engineers and managers who need to quickly assess the status and results of numerous individual power runs. The tool collates data from various sources, applies per-item derivation rules, and produces comprehensive reports that facilitate further analysis.

State the two properties most automation should guarantee:

- **Generative & idempotent:** re-running reproduces the same output tree from the
  same inputs.
- **Non-destructive to sources:** it does not modify its inputs.

---

## 2. Inputs (sources of truth)

List every input as a numbered source so the rest of the doc can reference `S1`, `S2`, …
Include the *exact* path shape and any auto-detection/selection rule.

The inputs below have a precendence order.  So if a parameter,  such as target runtime, exists in multiple sources, the first occurrence takes priority (first-listed wins).

From here on,  all paths are relative to $WORKAREA or --workarea <path> if $WORKAREA does not exist.  One of the two must exist.

A must have argument --dut must be provided to the script to specify the device under test.

The power output run areas are located in ONE of two places, **per module** (both
layouts can be present in the same workarea at once -- e.g. a bulk DUT-level run
uses the flat layout while a later single-partition rerun uses the partition-style
layout for just that module; probe both and merge):
$WORKAREA/output/<dut>/partition/<module>/pprtl2/<pass>/   (NOTE: "pprtl2", not "pprtl")
$WORKAREA/output/<dut>/pprtl2/<pass>/                       (no <module> path segment --
  module identity must come from S1's TOP_MODULE_NAME, not the path)

If there is more than one <pass> directory *for the same module* (by TOP_MODULE_NAME,
not by directory name -- pass-dir names don't reliably start with the module name),
the tool should select the newest one based on the directory timestamp.

Power runs can have up to two power analysis modes:
- vectorless
- timebased

Timebased mode may have one or more tests in it's output area


| # | Source | Provides | Notes (exact paths, selection rules, gotchas) |
|---|--------|----------|-----------------------------------------------|
| S1 | flow_inputs/config.log | PPRTL2 input configuration variables | An ASCII box-drawing TABLE (`\| Config \| Value \| Source \|` columns), NOT key=value. Duplicate keys (e.g. SDC_FILE) can appear more than once -- first occurrence wins. TOP_MODULE_NAME is the authoritative module identity (see path note above). POWER_ANALYSIS_MODE is written here as a run INPUT, so it's readable even if elab/power never ran. BLOCK is empty for a bulk DUT-level run, set to the module name for a single-block/partition-style rerun. |
| S2 | $WORKAREA/output/grdlbuild_power/logs/power.*.log | Contains grdlbuild netbatch logfile.  Exit status, memory, runtime. | |
| S2 | elab/log/flow.log | elaboration run results, errors | elaboration run log file;  exists for all power analysis modes |
| S3 | elab/elab.PASS | elaboration success indicator, no contents | exists for all power analysis modes |
| S4 | elab/reports/<module>.elab_clocks.rpt | contains list of applied clocks | exists for all power analysis modes |
| S5 | elab/pprtl_work/wattson.log | wattson summary run log execution errors | exists for all power analysis modes |
| S6 | elab/pprtl_work/vcs/vcs.log | wattson vcs run log execution errors | exists for all power analysis modes |
| S7 | fsdb/log/flow.log | fsdb run results and runtime information | only exists for timebased power analysis mode |
| S8 | fsdb/fsdb.PASS | fsdb success indicator, no contents | only exists for timebased power analysis mode |
| S9 | power/power.PASS | power success indicator, no contents | only exists for power analysis modes |
| S10 | power/<power analysis mode>/default/log/vectorless.flow.log | vectorless power run log | only exists for vectorless power analysis mode |
| S11| power/<power analysis mode>/default/reports/<module>.cells.rpt | overall cell count breakdowns by category| only exists for vectorless power analysis mode |
| S12| power/<power analysis mode>/default/reports/<module>.cge.hier.rpt | CGE and bit count data | only exists for vectorless power analysis mode |
| S13| power/<power analysis mode>/default/reports/<module>.power_groups.rpt | cell power group buckets | only exists for vectorless power analysis mode |
| S14| power/<power analysis mode>/<test name>/<instance>/log/timebased.flow.log | timebased power run log | only exists for timebased power analysis mode |
| S15| power/<power analysis mode>/<test name>/<instance>/reports/<module>.stat2.rpt | timebased power run summary | only exists for timebased power analysis mode |
| S16| power/<power analysis mode>/<test name>/<instance>/reports/<module>.cells.rpt | overall cell count breakdowns by category | only exists for timebased power analysis mode |
| S17| power/<power analysis mode>/<test name>/<instance>/reports/<module>.cge.hier.rpt | CGE and bit count data | only exists for timebased power analysis mode |
| S18| power/<power analysis mode>/<test name>/<instance>/reports/<module>.power_groups.rpt | cell power group buckets | only exists for timebased power analysis mode |
| S19| $WORKAREA/power/pprtl2/prep_pprtl2_report.summary | Partition count stats created before pprtl2 run execution | Plain text, not a table: `total partitions : N` and `ran : N (P%)` lines (regex-parsed). "total partitions" (N, e.g. 184) is the denominator for every percentage in 3.3; "ran" (the pre-flight-pass count, e.g. 181) is what S20's list actually contains. |
| S20| $WORKAREA/power/pprtl2/prep_pprtl2_partition.list | Target partition list for power runs (bare module name per line). **Every partition listed here must appear as at least one row in report_pprtl2.compute.csv/report_pprtl2.qor.csv**, even if it never reached elab or power (see 3.1/3.4). ||
| S21 | elab/pprtl_work/sdc/read_sdc.log | wattson read sdc log execution errors | exists for all power analysis modes; grep target for 3.6 (fail.details) |
| S22 | $WORKAREA/output/grdlbuild_power/logs/tasks_summary.log | Summary of tasks executed by grdlbuild including exit statuses  | NOT YET CONSUMED -- see §9 Non-goals. |


<!-- Tip: where a real input layout varies between targets, prefer AUTO-DETECT
     (probe the disk) over hardcoding, and record the observed variants. -->

** Precedence:** For the timebased power mode,  the stat2.rpt contains a summarized view of the data and has precedence over other sources containing the same data.

---

### 2.1 Pre-flight validation (fail fast)

**Checks:**
- Existence of $WORKAREA or --workarea <path> if $WORKAREA does not exist.
- Existence of the --dut argument.
- Existence of the expected power output run area(s) under $WORKAREA/output/<dut>/partition/<module>/pprtl2/<pass>/ or $WORKAREA/output/<dut>/pprtl2/<pass>/.
- Existence of <workarea>/power/pprtl2

---

## 3. Outputs (the generated tree)

Output root is <workarea>/power/pprtl2 (or the workarea specified by --workarea <path> if $WORKAREA does not exist).

Show the full output tree with a one-line comment per entry and its source.

```
<output_root>/
├── report_pprtl2.summary.md             # Human readable summary of execution rollup for all partitions
├── report_pprtl2.compute.csv            # Machine readable .csv containing cell count, runtime, and memory usage for each pprtl2 target stage (elab, fsdb, power)
├── report_pprtl2.qor.csv                # Machine readable .csv containing quality of results from each power run
├── report_pprtl2.fail.details           # Human readable summary of error message for stages that failed to provide some clue as to the cause of failure
```

**CSV files** When multiple power modes are present, and/or if there are multiple tests within the timebased mode, the reports will write one row for each existing combination of power mode and test instance.

**Completeness:** Every partition in S20 (prep_pprtl2_partition.list) must appear in
report_pprtl2.compute.csv and report_pprtl2.qor.csv, with at least one row, regardless
of how far it progressed:
- A partition that never started at all (no discoverable output run area) gets one
  row with `elab_run_status`/`fsdb_run_status`/`power_run_status` all `Not Ran`.
- A partition whose elab ran (Pass/Fail/Running) but whose power stage never started
  (no `power/vectorless` or `power/timebased` dir yet) gets one row with the real
  `elab_run_status` and `fsdb_run_status`/`power_run_status` both `Not Ran`.
- There is no "Skipped" status (see 3.1) -- an unreached stage is always `Not Ran`;
  determining *why* (never attempted vs. blocked by a failed dependency) is deferred.


## 3.1 How to determine by-stage (elab, fsdb, power) run status

- Pass   (Determined by whether the .PASS file exists for each stage)
- Fail   (Determined by the absence of the .PASS file for each stage.  If S2 is present, then capture the exit status also)
- Not Ran (Determined by whether execution has not started or was never reached, e.g.
  a stage blocked by an earlier failed/not-run dependency. There is no separate
  "Skipped" status -- disambiguating *why* a stage was Not Ran is deferred to a
  future iteration.)
- Running (Determined by whether flow execution is currently in progress).  You can use grdlbuild to check the status of the running stage... if the log is present but there is no netbatch exit footer then the run is in progress.
- Not Required (fsdb stage not required because vectorless power analysis mode)
- Unknown (Determined by whether the stage's status cannot be classified into any of the above categories)


## 3.2 How to determine runtime and memory usage

**Runtime:** The runtime for each stage (elab, fsdb, power) is recorded in the corresponding `_runtime` column in `report_pprtl2.compute.csv`. The `total_runtime` column is the sum of all individual stage runtimes.

**Memory Usage:** The peak memory usage for each stage is recorded in the corresponding `_peak_memory` column in `report_pprtl2.compute.csv`.   

- If grdlbuild is used, then look for power.*.elab.log and power.*.fsdb.log, power.*.power.log for the respective stage runtimes.  This information will be in the netbatch footer at the end of the run.
      - For runtime,  CPU time key,  the "WC" value such as 1d:14h:47m:11s. Also calculate and store this value in seconds.
      - For peak memory, Rusage  "Mem" field which is memory in GB
- If grdlbuild is not used, then the runtime and memory usage information must be obtained from the flow.log files
      - Runtime: Elapsed time for this session:
      - Peak Memory: Maximum memory usage for this session: 75,510,064 KB (72.01 GB)

Normalize all peak memory calculations to GB

Runtimes will be stored in two formats: DDd:HHh:MMm:SSs.   Zero padding will be applied to single-digit values for consistency.




## 3.3 report_pprtl2.summary.md
**Description:** This file contains a summary of the execution rollup for all partitions, including overall success/failure status and key metrics.

**Format:** Markdown output with the below format

```txt
Command Line: <command used to invoke the report generation including the python3 interpreter and any arguments>
Workarea: <workarea>
REF_MODEL:  Path to reference GK release model. The value is a symlink located at $WORKAREA/power/pprtl2/REF_MODEL. For example, if /nfs/site/disks/corimhoks_rtl_h2b_011/mroha/corhub_oks-a0-pprtl2-partitions-2/power/pprtl2/REF_MODEL exists, the value of this entry should be /nfs/site/disks/corhub_fe_mod_0000/corhub_oks/corhub_oks-a0-corhub_oks-26ww29m .   NA if it does not exist.
SDC_ARCHIVE: Path to SDC release area.  Path to the symlink pointed to by $WORKAREA/power/pprtl2/SDC_ARCHIVE. For example, if /nfs/site/disks/corimhoks_rtl_h2b_011/mroha/corhub_oks-a0-pprtl2-partitions-2/power/pprtl2/SDC_ARCHIVE exists, the value of this entry should be /nfs/site/disks/corimh.arc.proj_archive/arc .   NA if it does not exist.
DUT: DUT name from --dut
total partitions from S19 ("total partitions" line; S20's list is the pre-flight-pass
subset, not the full denominator)
total partitions pass pre-flight from S19 <count>  <XX%>   where XX% is preflight pass divided by total partitions
total partitions with at least one grdlbuild log: <count>  <XX%>   where XX% is the number of partitions with grdlbuild logs divided by total partitions. A partition could have either complete or partial grdlbuild logs.
total partitions with at least one stage flow.log file: <count>  <XX%>   where XX% is the number of partitions with at least one stage flow.log file divided by total partitions.

vectorless:
total partitions pass elab: <count>  <YY%>   where YY%  elab pass divided by total partitions
total partitions pass vectorless power: <count>  <ZZ%>   where ZZ% is power pass divided by total partitions

timebased:
total partitions pass elab: <count>  <YY%>   where YY%  elab pass divided by total partitions
total partitions pass timebased power: <count>  <ZZ%>   where ZZ% is power pass divided by total partitions
total partitions that executed greater than one testname: <count>

Partitions that executed greater than one test in timebased run:
<partition1>
<partition2>
```

**Note: If no partitions executed greater than one test in the timebased run, then write "No Partitions Executed Greater Than One Test" in the corresponding section.**


## 3.4 report_pprtl2.compute.csv

**Description:** This file contains machine-readable data for each pprtl2 target stage, including cell count, runtime, and memory usage.

**Format:** CSV with the following columns:

```csv fields
module
power_mode  # vectorless or timebased
test_name   # example:  d2d_opt_i2c_high_3R1W_C2M_MCR_HIGH_25ww20a_525g01
instance    # RTL instance path component under the test (e.g. "d2d_1_d2d1");
            # blank for vectorless. Real timebased runs key their reports/logs
            # by <test_name>/<instance>, and a test_name can have >1 instance,
            # so this is needed for row uniqueness -- not redundant with test_name.
elab_run_status   # Pass,  Fail=3, Running, Not Ran
fsdb_run_status   # Pass,  Fail=-314, Running, Not Ran, Not Required
power_run_status  # Pass,  Fail=2, Running, Not Ran
cell_count   # Total number of cells in the design
elab_runtime
elab_runtime_seconds
fsdb_runtime
fsdb_runtime_seconds
power_runtime
power_runtime_seconds
total_runtime
total_runtime_seconds
elab_peak_memory
fsdb_peak_memory
power_peak_memory
```

## 3.5 report_pprtl2.qor.csv
**Description:** This file contains machine-readable quality of results (QoR) data for each power run.

**Format:** CSV with the following columns:

```csv fields
module
power_mode  (vectorless or timebased)
test_name  (example:  d2d_opt_i2c_high_3R1W_C2M_MCR_HIGH_25ww20a_525g01)
instance   (see 3.4 -- blank for vectorless, needed for timebased row uniqueness)
elab_run_status   # Pass,  Fail=3, Running, Not Ran
fsdb_run_status   # Pass,  Fail=-314, Running, Not Ran
power_run_status  # Pass,  Fail=2, Running, Not Ran
cell_count        # comes from stat2.rpt or cells.rpt
register_cell_count     # comes from stat2.rpt or power_groups.rpt
sequential_cell_count   # comes from stat2.rpt or power_groups.rpt
register_bit_count      # come from cge.hier.rpt
untraced_sequentials    # % Round to 2 decimal places.
CGR                     # % Round to 2 decimal places.
CGE                     # % Round to 2 decimal places.
DACGE                   # % Round to 2 decimal places.
```


**Finding register_bit_count, CGR, CGE, DACGE**
- **register_bit_count:** comes from cge.hier.rpt.  It will be row containing just the module name in the "Name" field.  Register bit count is extracted from this row.
- **CGR:** comes from cge.hier.rpt.  It will be row containing just the module name in the "Name" field.  CGR (%) is extracted from this row.
- **CGE:** comes from cge.hier.rpt.  It will be row containing just the module name in the "Name" field.  CGE (%)  is extracted from this row.
- **DACGE:** comes from cge.hier.rpt.  It will be row containing just the module name in the "Name" field.   DACGE (%) is extracted from this row.


**Calculating untraced_sequentual %**
- First option is to take directly from stat2.rpt, where it is reported as a percentage.  Round to 2 decimal places.
- Second option is to calculate it manually: `(sequential_cell_count / (register_cell_count+sequential_cell_count)) * 100`.  Round to 2 decimal places.


## 3.6 report_pprtl2.fail.details

**Description:** This file contains detailed information about failed partitions, including the reason for failure and any relevant logs.

**Format:** Plain text with the following structure:

```txt
Partition: <partition_name>
Test: <test_name>
Failure reason: <reason>
Grep results:
Log: <path_to_gradle_log>
Results of grep <pattern>

Log: <path to flow.log>
Results of grep <pattern>

Log: <path to wattson.log>
Results of grep <pattern>

Log: <path to vcs.log>
Results of grep <pattern>

Log: <path to read_sdc.log>       # S21 -- elab/pprtl_work/sdc/read_sdc.log
Results of grep <pattern>
```

- Grep pattern is: /(Error:)|(Error\-)|(\[ERROR\])/    # /<regex here>/
- Include 1 line before and 3 lines after each match. Merge overlapping/adjacent
  windows into one block; separate windows within the same log are joined with
  a bare `...` line.
- If no results return from grep,  then indicate "No matches found" under the corresponding log section.
- For gradle and flow.log sections,  create a .log entry for each target.  Example:  elab flow.log,  fsdb flow.log, power flow.log.  For power you could have vectorless and timebased,  and for timebased you could have one or more tests.
- Only partitions with at least one Fail=<n>/Fail status (elab, fsdb, or power) get
  an entry; Not Ran/Running/Pass-only partitions are omitted entirely.


## 3.7 report_pprtl2.terminology.md

**Description:** This file contains definitions and explanations of key terms used throughout the pprtl2 reports.
Write direct output,  no processing.


| Metric | PPRTL1 | PPRTL2 |
| % clock gated registers (static) | Static Clock Gating Efficiency (SCGE) | Clock Gating Ratio (CGR) |
| % gated clock cycles; lacks correlation with data activity | Dynamic Clock Gating Efficiency (DCGE) | Clock Gating Efficiency (CGE) |
| CGE +  [data toggle cycles / root clock cycles] | Data Aware Clock Gating Efficiency (DACGE) | Data Aware Clock Gating Efficiency (DACGE) |
| % untraced sequentials | - | Untraced Sequentials (%) |

**Notes:**
- Static CGE is your upper bounds
- DACGE will be the same or higher than CGE/DCGE by nature of the arithmetic.

---

## 4. Per-item derivation rules

**Reports** (write these every run, overwriting prior copies):

---

## 5. CLI

```
<tool>.py \
  --dut         <dut>
  --workarea    <path>        # default: $WORKAREA if set
  [--dry-run] [--force] [--verbose]
```

Conventions (recommended for all automation):
- `--dry-run` — print the plan (every planned path/action), write nothing.
- `--force` — for TREE-GENERATING tools (e.g. prep_pprtl2): overwrite existing
  outputs; default **skips** existing (idempotent). For a pure REPORT-generating
  tool like this one, all 5 output files are always regenerated/overwritten every
  run (per §4) since they're cheap to rebuild and must reflect current state --
  `--force` is accepted for CLI parity but is a no-op here.
- `--verbose` — log each file written.
- Validate all inputs before writing any output (fail fast).

---

## 6. Decisions log (resolved questions & notes)

Keep this section append-only. It is what lets the spec be re-ingested reliably.

**Verified on disk (2026-07-25/26), against 3 real workareas** --
`corhub_oks-a0-pprtl2-partitions-2` (vectorless, bulk/flat layout),
`corhub_oks-a0-pprtl2-partitions-3` (partition-style layout, 3 modules only),
`dmrhub2-a0-pprtl-statecount` (timebased, no grdlbuild -- `nb_logs/` instead):
- Partition-style path is `output/<dut>/partition/<module>/pprtl2/<pass>/` (pprtl2,
  not "pprtl"). Both layouts can be valid for the SAME workarea at once, one style
  per module (bulk DUT-level run = flat; single-block rerun = partition-style,
  config.log BLOCK=<module>/TOP_IP_NAME=<module> instead of BLOCK=empty/TOP_IP_NAME=<dut>).
- flow_inputs/config.log is an ASCII box-drawing table (`| Config | Value | Source |`),
  not key=value. TOP_MODULE_NAME is the only reliable module identity (pass-dir names
  don't consistently start with the module name, e.g. `hamvf_pass01` vs
  `d2d1_state_pprtl2_X-2025.06-SP3-20260214_pass01`).
- fsdb sources are nested per test+instance (mirrors power/timebased/):
  `fsdb/<test_name>/<instance>/{fsdb.PASS,log/flow.log}`.
- Each pass-dir directly contains `elab/, flow_inputs/, flow_outputs/, power/`
  (+`fsdb/` if timebased) -- no extra module-name nesting under the flat layout.
- `power/vectorless/default/{log,reports}/` (single "default" dir);
  `power/timebased/<test_name>/<instance>/{log,reports}/`.
- `*.cells.rpt`: `Key: value` lines (`Total_cells`, `Register_cells`,
  `Sequential_cells`, ..., note upstream typo `Clock_newtwork_cells`).
- `*.power_groups.rpt`: fixed-width table, rows clock_network/register/
  combinational/sequential/memory/io_pad/black_box with comma-formatted Size.
- `*.cge.hier.rpt`: fixed-width table; the row whose bare Name == module name
  (no "/") is the top-level one (columns: Register Bit Count, Gated Register Bit
  Count, CGR (%), CGE (%), DACGE (%), Name).
- `*.stat2.rpt` (timebased only): plain `Key: value` lines, not a table. Fields
  "Total cell count"/"Register Count"/"Sequential cells count" match cells.rpt/
  power_groups.rpt for the same run (may differ slightly -- stat2 wins per the
  §2 precedence rule). "SCGE"/"DCGE"/"DACGE" here equal CGR/CGE/DACGE from the
  module's cge.hier.rpt row numerically. "Untraced Sequential ratio" is a 0-1
  fraction (not already a %) -- multiply by 100.
- grdlbuild netbatch footer (`output/grdlbuild_power/logs/power.<module>.pprtl2_<stage>.log`,
  only present when grdlbuild was used): `Exit Status`, `WC <fmt>` (format varies:
  `3h:00m:37s` with no days, or `1d:14h:47m:11s` with days -- parse flexibly), and
  `Rusage Stats ... Mem:<n>` where **n is in MEGABYTES** (user-confirmed; convert
  to GB via `n / 1000`, decimal not binary).
- `elab/log/flow.log` (and the fsdb/vectorless/timebased equivalents) ALWAYS carry
  `Maximum memory usage for this session: ... KB (X.XX GB)` and
  `Elapsed time for this session: N seconds` near the end when the stage finished,
  regardless of grdlbuild use (grdlbuild just wraps `make elab/power`). Also a
  `"<stage> stage passed successfully.."` / `"<stage> stage failed"` line.
- `prep_pprtl2_report.summary` (S19) is plain text (`total partitions : N`,
  `ran : N (P%)`), not a table. `prep_pprtl2_partition.list` (S20) has exactly the
  "ran" count of bare module names, one per line -- it's the pre-flight-PASS
  subset, not the full target set (S19's "total partitions" is the full set).
- REF_MODEL/SDC_ARCHIVE under `power/pprtl2/` are designer-made symlinks; the
  summary.md must print the resolved TARGET path (`Path.resolve()`), not the
  symlink's own path.
- `elab/pprtl_work/sdc/read_sdc.log` (S21) exists at that exact path for every
  module that reached elab, regardless of power mode.
- `output/grdlbuild_power/logs/tasks_summary.log` (S22) exists when grdlbuild was
  used and gives clean per-module-per-stage `Task Path: :power:<module>:pprtl2_<stage>`,
  `Task Status: Success/Failed/Skipped`, `Exit Status`, `Run Time` -- considered as
  a simpler alternative status/runtime source but NOT adopted (see Q7 below); not
  yet consumed by this tool at all (see §9 Non-goals).

- **Q1** Should module identity/grouping use path segments or config.log? --
  Use `TOP_MODULE_NAME` from S1; group all discovered pass-dirs by it and pick the
  newest (by directory mtime) per module.
- **Q2** How to parse config.log? -- As the ASCII table it actually is (see above),
  not key=value.
- **Q3** Flat vs. nested fsdb paths? -- Nested per test+instance (see above).
- **Q4** Is grdlbuild's `tasks_summary.log`/`failure_tasks_summary.log` (S22) a
  better primary source for per-module-per-stage status/runtime than raw log
  parsing? -- Investigated and offered; user declined, chose to strictly follow
  the original S2 netbatch-footer + flow.log approach. Kept as a documented,
  not-yet-implemented option (§9).
- **Q5** Netbatch Rusage "Mem" field unit? -- Megabytes (user-confirmed from a
  real example: `Mem:183730` == "183.730 GB" after `/1000`).
- **Q6** Is the `partition/<module>/pprtl2/<pass>/` layout still needed? -- Yes,
  confirmed with a real example (`corhub_oks-a0-pprtl2-partitions-3`).
- **Q7** Should `report_pprtl2.compute.csv`/`.qor.csv` cover every S20 partition,
  even ones that never reached elab or power? -- Yes (found via a real discrepancy:
  184 S19 total / 181 S20 pre-flight-pass vs. only 170 CSV rows in a real workarea;
  12 modules had elab `Fail=2` and no `power/` dir at all and were silently
  dropped). Fixed by iterating `set(S20) | set(discovered)` and emitting a
  fallback row (`Not Ran` for stages never reached) for every target module.
- **Q8** Keep the spec's original "Skipped" status? -- No, removed entirely
  (2026-07-26 decision, reversing an earlier plan to detect it via
  `SKIP_STAGES`). Only Pass/Fail=&lt;n&gt;/Fail/Running/Not Ran/Not Required are used;
  disambiguating *why* something is `Not Ran` is deferred.
- **Q9** Should REF_MODEL/SDC_ARCHIVE show the symlink path or its target? --
  The resolved target (see above).
- **Q10** Should the `TOP_IP_NAME` line stay in summary.md? -- No, removed
  (2026-07-26); replaced by two coverage stat lines (grdlbuild-log coverage,
  flow.log coverage) that turned out to be more broadly useful.

---

## 7. Test plan

Implemented in `scripts/pprtl2/test_report_pprtl2.py` (54 tests, table-driven,
zero live-tool/disk dependency beyond `tempfile.TemporaryDirectory`):

1. **Unit -- input/report-file parsing:** `TestConfigTableParsing`,
   `TestReportParsers`, `TestNetbatchAndFlowLogFooters`, `TestGrepContextBlocks`,
   `TestSymlinkTarget`, `TestReadPartitionList` -- each pure parser gets fixture
   text (copied verbatim from real files) and asserts the extracted fields,
   including precedence/edge cases (first-key-wins, missing file, no matches,
   adjacent vs. distant grep windows).
2. **Unit -- per-stage status logic:** `TestEvaluateStage` -- Pass (marker file),
   Fail (grdlbuild exit code, preferred over flow.log), Running (log present, no
   "Elapsed time" line yet), Not Ran (no logs at all).
3. **Unit -- QoR precedence:** `TestQorExtraction` -- vectorless (cells.rpt +
   cge.hier.rpt) vs. timebased (stat2.rpt wins per §2's precedence rule).
4. **Integration -- discovery + row assembly:** `TestBuildRows` -- builds a fake
   on-disk tree (both output layouts, vectorless and timebased-with-2-tests,
   newest-pass-dir selection, elab-only/no-power-dir fallback rows, never-
   discovered ghost modules) and asserts the resulting `Row` list end-to-end.
5. **Integration -- CLI/pre-flight/main():** `TestPreflightAndCli` -- every
   `preflight()` failure mode, `resolve_config()`'s `$WORKAREA` fallback and
   missing-workarea error, and `main()`'s exit codes (2 for pre-flight failure,
   2 for zero discovered rows, 0 for `--dry-run` writing nothing, 0 for a full
   run writing all 5 files).
6. **Integration -- report writers:** `TestCsvAndReportWriters`,
   `TestRenderSummaryMd`, `TestGenerateReports` -- CSV headers/rows, summary.md's
   command-line/count+percent lines and the no-multi-test fallback note,
   fail.details' per-module grouping and log-block grep windows, and
   `generate_reports()`'s all-5-files-written contract.
7. **Smoke (manual, not automated):** run against the 3 real workareas above and
   diff key facts against hand-verified ground truth (see the Decisions log).
   Re-run after every spec change to catch regressions before they reach users.

---

## 8. Implementation plan (phased)

- **Phase 0 (this spec):** ✅ **DONE** -- scope approved via iterative clarifying
  Q&A (see §6) rather than a single upfront sign-off; the spec was re-ingested
  and corrected after every verified-on-disk discovery.
- **Phase 1:** ✅ **DONE** -- CLI (`--dut`/`--workarea`/`--dry-run`/`--force`/
  `--verbose`), pre-flight validation, S1 config.log table parsing, dual-layout
  pass-dir discovery, `--dry-run` plan.
- **Phase 2:** ✅ **DONE** -- static output (`report_pprtl2.terminology.md`,
  direct verbatim write, no processing).
- **Phase 3:** ✅ **DONE** -- all 4 generated reports (summary.md, compute.csv,
  qor.csv, fail.details) wired to real parsers; no subprocess helpers needed
  (this is a pure report-over-existing-artifacts tool, unlike prep_pprtl2).
- **Phase 4:** ✅ **DONE** -- smoke-tested against 3 real workareas covering
  vectorless/timebased/grdlbuild/non-grdlbuild/dual-layout combinations; a real
  data-driven bug (missing partitions, §6 Q7) was found and fixed this way.

---

## 9. Non-goals

- **Orchestrating pprtl2 runs.** This tool only reads an existing run area; it
  never invokes `pprtl`, `grdlbuild`, `make elab/power`, etc. (see §1's
  non-destructive-to-sources guarantee).
- **S22 (`tasks_summary.log`) consumption.** Identified as a source and
  considered as a simpler status/runtime alternative (§6 Q4), but not adopted or
  implemented -- the per-row grdlbuild-footer/flow.log approach remains the sole
  source. Revisit if per-module log parsing ever proves unreliable in practice.
- **Disambiguating *why* a stage is `Not Ran`** (never attempted vs. blocked by a
  failed dependency vs. intentionally skipped). Deferred per §6 Q8.
- **Legacy `pprtl` (v1, not pprtl2) output layouts.** Out of scope entirely.
- **Modifying or pruning stale reports** from a previous run whose target set
  has since shrunk -- reports are fully regenerated every run from the current
  S20 list, so stale per-module data simply won't appear; there is no tree to
  prune (unlike prep_pprtl2's generated collateral tree).

---

## Appendix A — Reusable engineering checklist

Patterns that repeatedly paid off (from the prep_pprtl2 build):

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
- [ ] **Phased delivery** with tests per phase; keep Status current.
- [ ] **Note caveats honestly**: e.g. `--force` overwrites regenerated files but does
      not prune stale outputs from items that flipped to skipped/failed.
