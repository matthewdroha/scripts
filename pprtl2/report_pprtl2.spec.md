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
    if it never ran" completeness guarantee, grep-with-context-window failure
    triage, and a real mid-project pivot to a single ground-truth status source
    (grdlbuild logs) after two real workareas exposed drift in the original
    approach. See §6 for the full list of verified-on-disk corrections.)

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

Status: **DONE** — Phases 1-5 complete and smoke-tested against real workareas
  (2026-07-26, 2026-08-11, 2026-08-12). See §8 for phase-by-phase results and §6
  for every verified-on-disk correction to this doc's original assumptions.
Owner: mroha
Language: Python 3 (driver)
Scope: Report generation for COR pprtl2 run area.  The run area can contain hundreds of individual power runs and these needs to be conveniently summarized and the data collated for analysis.
Implementation: scripts/pprtl2/report_pprtl2.py (+ scripts/pprtl2/test_report_pprtl2.py, 68 unit tests).

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

Timebased mode may have one or more tests in it's output area. On disk this
means one or more test-name subdirectories directly under
`power/timebased/`, e.g. `power/timebased/test1/`, `power/timebased/test2/`
(each with its own instance subdirectory underneath, per S14-S18/S25's path
shape) -- `build_rows()` discovers every test-name dir under `power/timebased/`
and produces one row per (test_name, instance) pair, all sharing the same
module-level elab/fsdb/timebased-power status (§3.1). Verified (2026-08-12)
against both a synthetic 2-test tree matching this exact hypothetical layout
and the existing `test_timebased_module_with_two_tests_shares_module_level_fsdb_power_status`
unit test.


| # | Source | Provides | Notes (exact paths, selection rules, gotchas) |
|---|--------|----------|-----------------------------------------------|
| S1 | flow_inputs/config.log | PPRTL2 input configuration variables | An ASCII box-drawing TABLE (`\| Config \| Value \| Source \|` columns), NOT key=value. Duplicate keys (e.g. SDC_FILE) can appear more than once -- first occurrence wins. TOP_MODULE_NAME is the authoritative module identity (see path note above). POWER_ANALYSIS_MODE is written here as a run INPUT, so it's readable even if elab/power never ran -- BUT for a dual-mode partition (both vectorless and timebased), config.log is APPENDED TO once per stage invocation, so it holds multiple stacked blocks with alternating POWER_ANALYSIS_MODE values; don't rely on this field to infer mode when both modes are present (use on-disk power/vectorless + power/timebased dir presence instead). BLOCK is empty for a bulk DUT-level run, set to the module name for a single-block/partition-style rerun. |
| S2 | $WORKAREA/output/grdlbuild_power/logs/power.\<module\>.pprtl2_\<activity\>.log | grdlbuild netbatch job log -- SOLE ground truth for Pass/Fail/Running/Not-Started (see 3.1). \<activity\> is one of `elab`, `fsdb`, `power_vectorless`, `power_timebased` (NOTE: power is split by mode, not a single shared `pprtl2_power.log`). The `elab` activity's log is ALSO the source of VERDI_VERSION/PPRTL_VERSION (see below). | Header block starts with a line matching `Logfile\s*:`; footer block (only present once the job finishes) has `Exit Status\s*:\s*<n>`, `WC <fmt>` runtime (with or without a leading `<N>d:`), and `Rusage Stats ... Mem:<n>` (n in MEGABYTES -- divide by 1000 for GB). elab/fsdb/power_timebased are each ONE task per module (fsdb/power_timebased cover every timebased test in a single job, not one job per test). VERDI_VERSION comes from the elab log's `Info: VERDI_HOME = .../verdi3/<VERSION>` line; PPRTL_VERSION comes from its `Version: <VERSION> for linux64 - <date>` line (the "PrimePower RTL [Wattson Inside]" banner). Both are module-level (one elab run per module). |
| S3 | elab/elab.PASS | elaboration success indicator, no contents | NOT USED for status (S2/grdlbuild is sole truth) -- kept only as a historical on-disk artifact. |
| S4 | elab/reports/<module>.elab_clocks.rpt | contains list of applied clocks | exists for all power analysis modes |
| S5 | elab/pprtl_work/wattson.log | wattson summary run log execution errors | exists for all power analysis modes |
| S6 | elab/pprtl_work/vcs/vcs.log | wattson vcs run log execution errors; also the source of VCS_VERSION (2nd line: ``Version <token> -- <date>``, with a trailing ``_Full64`` suffix trimmed off if present, e.g. ``X-2025.06-SP2-3_Full64`` -> ``X-2025.06-SP2-3``) | exists for all power analysis modes; VCS_VERSION is module-level (one elab run per module) |
| S7 | fsdb/<test name>/<instance>/log/flow.log | fsdb run results and runtime information (memory/runtime fallback only -- see 3.2) | only exists for timebased power analysis mode |
| S8 | fsdb/<test name>/<instance>/fsdb.PASS | fsdb success indicator, no contents | NOT USED for status (S2/grdlbuild is sole truth) |
| S9 | power/power.PASS | power success indicator, no contents | NOT USED for status (S2/grdlbuild is sole truth) |
| S10 | power/<power analysis mode>/default/log/vectorless.flow.log | vectorless power run log (memory/runtime fallback only) | only exists for vectorless power analysis mode |
| S11| power/<power analysis mode>/default/reports/<module>.cells.rpt | overall cell count breakdowns by category| only exists for vectorless power analysis mode |
| S12| power/<power analysis mode>/default/reports/<module>.cge.hier.rpt | CGE and bit count data | only exists for vectorless power analysis mode |
| S13| power/<power analysis mode>/default/reports/<module>.power_groups.rpt | cell power group buckets | only exists for vectorless power analysis mode |
| S14| power/<power analysis mode>/<test name>/<instance>/log/timebased.flow.log | timebased power run log (memory/runtime fallback only) | only exists for timebased power analysis mode |
| S15| power/<power analysis mode>/<test name>/<instance>/reports/<module>.stat2.rpt | timebased power run summary | only exists for timebased power analysis mode |
| S16| power/<power analysis mode>/<test name>/<instance>/reports/<module>.cells.rpt | overall cell count breakdowns by category | only exists for timebased power analysis mode |
| S17| power/<power analysis mode>/<test name>/<instance>/reports/<module>.cge.hier.rpt | CGE and bit count data | only exists for timebased power analysis mode |
| S18| power/<power analysis mode>/<test name>/<instance>/reports/<module>.power_groups.rpt | cell power group buckets | only exists for timebased power analysis mode |
| S19| $WORKAREA/power/pprtl2/prep_pprtl2_report.summary | Partition count stats created before pprtl2 run execution | Plain text, not a table: `total partitions : N` line (regex-parsed) is the ONLY field consumed -- it's the denominator for the elab:/vectorless: sections in 3.3. The rest of this file (`vectorless/timebased setup generated/skipped`, `missing 2stage/hiplist/clocks`, `timebased not in mtl`, `timebased fsdb missing`, etc.) is prep_pprtl2's own pre-flight report and is NOT otherwise parsed by report_pprtl2 -- there is no more "ran" line/pre-flight-pass line in report_pprtl2.summary.md (removed, see §6). |
| S20| $WORKAREA/power/pprtl2/prep_pprtl2_partition.list | Target partition list for vectorless+elab (bare module name per line). **Every partition listed here must appear as at least one row in report_pprtl2.compute.csv/report_pprtl2.qor.csv**, even if it never reached elab or power (see 3.1/3.4). Also the denominator for the elab:/vectorless: sections of 3.3. ||
| S21 | elab/pprtl_work/sdc/read_sdc.log | wattson read sdc log execution errors | exists for all power analysis modes; grep target for 3.6 (fail.details) |
| S22 | $WORKAREA/output/grdlbuild_power/logs/tasks_summary.log | Summary of tasks executed by grdlbuild including exit statuses  | NOT YET CONSUMED -- see §9 Non-goals. |
| S23 | $WORKAREA/power/pprtl2/prep_pprtl2_timebased_partition.list | Target partition list for the timebased-eligible subset (bare module name per line; a subset of S20, e.g. it excludes partitions prep_pprtl2 found "not in mtl"). Denominator for the fsdb:/timebased power: sections of 3.3. | |
| S24 | $WORKAREA/power/pprtl2/MTL_FILE | Optional symlink to the MTL file used for timebased test selection, created by prep_pprtl2 alongside REF_MODEL/SDC_ARCHIVE. | Printed in 3.3 like REF_MODEL/SDC_ARCHIVE (resolved symlink target, "NA" if absent). |
| S25 | power/vectorless/default/reports/\<module\>.rtl_metrics.hier.csv (vectorless) or power/timebased/\<test name\>/\<instance\>/reports/\<module\>.rtl_metrics.hier.csv (timebased) | Hierarchical RTL metrics for the partition. **PRIMARY source (2026-08-12) for cell_count/register_cell_count/sequential_cell_count/register_bit_count/CGR/CGE/DACGE/flop_cell_count/mbflop_cell_count/eqfb/latch_cell_count/mblatch_cell_count/eqlb -- wins over stat2.rpt (S15) too.** | A huge fixed-column CSV (10000+ hierarchy rows for a large partition). The module's own top-of-hierarchy row is identified by ``Hierarchy Level`` == "0" AND ``Module Name`` == the partition name (it is also always the first data row on real data). Parsing STOPS as soon as that row is found -- the rest of the file (every sub-instance row) is never read, which matters a lot given the file size. The old cells.rpt (S11/S16)/power_groups.rpt/cge.hier.rpt (S12/S17) sources have been retired entirely -- see §6 Q19. |


<!-- Tip: where a real input layout varies between targets, prefer AUTO-DETECT
     (probe the disk) over hardcoding, and record the observed variants. -->

** Precedence (updated 2026-08-12, see §6 Q18-Q19):** S25 (`<module>.rtl_metrics.hier.csv`)
is now the primary source for cell_count/register_cell_count/sequential_cell_count/
register_bit_count/CGR/CGE/DACGE/flop_cell_count/mbflop_cell_count/eqfb/
latch_cell_count/mblatch_cell_count/eqlb, for BOTH vectorless and timebased mode --
it wins over stat2.rpt (S15) too. stat2.rpt's only remaining role is supplying the
timebased-only annotation fields (primary_io_annotation/bb_annotation/
seq_annotation, blank for vectorless). The old cells.rpt (S11/S16)/
power_groups.rpt/cge.hier.rpt (S12/S17) sources have been retired entirely --
no fallback to them if S25 is missing or the module's row isn't found (fields
are just blank in that case, same as any other unavailable QoR field).

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
├── report_pprtl2.summary                # Human readable summary of execution rollup for all partitions
├── report_pprtl2.compute.csv            # Machine readable .csv containing cell count, runtime, and memory usage for each pprtl2 target stage (elab, fsdb, power)
├── report_pprtl2.qor.csv                # Machine readable .csv containing quality of results from each power run
├── report_pprtl2.fail.details           # Human readable summary of error message for stages that failed to provide some clue as to the cause of failure
├── report_pprtl2.fail.details           # Human readable summary of error message for stages that failed to provide some clue as to the cause of failure
├── report_pprtl2.README                 # Human readable reference of key terms.  All static content.
```

**CSV files** When multiple power modes are present, and/or if there are multiple tests within the timebased mode, the reports will write one row for each existing combination of power mode and test instance.

**Completeness:** Every partition in S20 (prep_pprtl2_partition.list) must appear in
report_pprtl2.compute.csv and report_pprtl2.qor.csv, with at least one row, regardless
of how far it progressed:
- A partition that never started at all (no grdlbuild log for the activity) gets
  `Not Started` for that stage (see 3.1).
- A partition whose elab ran (Pass/Fail/Running) but whose power stage never started
  gets one row with the real `elab_run_status` and `fsdb_run_status`/`power_run_status`
  both `Not Started`.
- There is no "Skipped" status (see 3.1) -- an unreached stage is always `Not Started`;
  determining *why* (never attempted vs. blocked by a failed dependency) is deferred.


## 3.1 How to determine by-stage (elab, fsdb, power) run status

The grdlbuild netbatch job log (S2, `output/grdlbuild_power/logs/power.<module>.pprtl2_<activity>.log`)
is the SOLE ground truth for elab/fsdb/power_vectorless/power_timebased status --
not the `.PASS` marker files (S3/S8/S9), which are historical artifacts only:

- Pass: the log's netbatch footer has `Exit Status\s*:\s*0`.
- Fail=<n>: the footer has `Exit Status\s*:\s*<n>` for any non-zero `<n>`.
- Running: the log file exists (netbatch header `Logfile\s*:` present) but the
  netbatch footer (`Exit Status\s*:`) does not exist yet -- the job is still
  executing.
- Not Started: the grdlbuild log for that activity does not exist at all.
- Not Required: fsdb/timebased-power for a vectorless-only row (no timebased
  mode for that partition at all).

There is no "Skipped" status -- a stage that never ran (whether truly skipped
or blocked by a failed dependency) is always `Not Started`; disambiguating
*why* is deferred to a future iteration.

**Important:** elab is run exactly ONCE per module regardless of how many power
modes it has (vectorless, timebased, or both share the same elaboration) --
so is fsdb and timebased power: grdlbuild runs ONE `pprtl2_fsdb`/`pprtl2_power_timebased`
job per module covering every timebased test in that job, not one job per test.
That means `elab_run_status`/`fsdb_run_status`/`power_run_status` (timebased) are
the SAME value across every test-name row of a given module -- only
`power_run_status` for a *vectorless* row is independent (there's exactly one
vectorless row per module anyway).


## 3.2 How to determine runtime and memory usage

**Runtime:** The runtime for each stage (elab, fsdb, power) is recorded in the corresponding `_runtime` column in `report_pprtl2.compute.csv`. The `total_runtime` column is the sum of all individual stage runtimes.

**Memory Usage:** The peak memory usage for each stage is recorded in the corresponding `_peak_memory` column in `report_pprtl2.compute.csv`.

These are supplementary metrics only -- unlike status (3.1), runtime/memory MAY
fall back to flow.log when the grdlbuild footer doesn't have them (rare in
practice, since the footer normally has both once a job finishes):

- The grdlbuild footer (S2) is checked FIRST: `CPU time ... WC <fmt>` for
  runtime (`1d:14h:47m:11s` or `3h:00m:37s` with no leading day count -- parse
  flexibly; store both the formatted string and raw seconds), and
  `Rusage Stats ... Mem:<n>` for peak memory (n in MEGABYTES; divide by 1000
  for GB).
- If the footer is missing runtime/memory (e.g. the job is `Running` and has
  no footer yet), fall back to the stage's own flow.log:
      - Runtime: `Elapsed time for this session: <n> seconds`
      - Peak Memory: `Maximum memory usage for this session: 75,510,064 KB (72.01 GB)`

Normalize all peak memory calculations to GB

Runtimes will be stored in two formats: DDd:HHh:MMm:SSs.   Zero padding will be applied to single-digit values for consistency.




## 3.3 report_pprtl2.summary
**Description:** This file contains a summary of the execution rollup for all partitions, including overall success/failure status and key metrics.

**Format:** Markdown output with the below format

```txt
Command Line: <command used to invoke the report generation including the python3 interpreter and any arguments>
Workarea: <workarea>
REF_MODEL:  Path to reference GK release model. The value is a symlink located at $WORKAREA/power/pprtl2/REF_MODEL. Resolved symlink TARGET, or "NA" if it does not exist.
SDC_ARCHIVE: Path to SDC release area.  Path to the symlink pointed to by $WORKAREA/power/pprtl2/SDC_ARCHIVE. Resolved symlink TARGET, or "NA" if it does not exist.
MTL_FILE: Path to the MTL file used for timebased test selection (S24, $WORKAREA/power/pprtl2/MTL_FILE). Resolved symlink TARGET (same treatment as REF_MODEL/SDC_ARCHIVE), or "NA" if it does not exist.
DUT: DUT name from --dut
total partitions <count>                          # S19's "total partitions" line
total partitions with at least one grdlbuild log: <count>  <XX%>   where XX% is the number of partitions with grdlbuild logs divided by total partitions. A partition could have either complete or partial grdlbuild logs.
total partitions with at least one stage flow.log file: <count>  <XX%>   where XX% is the number of partitions with at least one stage flow.log file divided by total partitions.

elab:
total partitions pass elab: <count>  <YY%>
total partitions fail elab:  <count>  <YY%>
total partitions still running elab:  <count>  <YY%>
total partitions not started elab:  <count>  <YY%>

vectorless:
total partitions pass vectorless power: <count>  <YY%>
total partitions fail vectorless power:  <count>  <YY%>
total partitions still running vectorless power:  <count>  <YY%>
total partitions not started vectorless power:  <count>  <YY%>

timebased:
total partitions pass fsdb: <count>  <YY%>
total partitions fail fsdb:  <count>  <YY%>
total partitions still running fsdb:  <count>  <YY%>
total partitions not started fsdb:  <count>  <YY%>

total partitions pass timebased power: <count>  <YY%>
total partitions fail timebased power:  <count>  <YY%>
total partitions still running timebased power:  <count>  <YY%>
total partitions not started timebased power:  <count>  <YY%>

Action Required:

Partitions that fail elab:
<partition 1>  <path to grdlbuild log file>
<partition 2>  <path to grdlbuild log file>

Partitions that are still running elab:
<partition 1>  <path to grdlbuild log file>
<partition 2>  <path to grdlbuild log file>

Partitions that have not started elab:
<partition 1>
<partition 2>

Partitions that fail vectorless power:
<partition 1>  <path to grdlbuild log file>

Partitions that are still running vectorless power:
<partition 1>  <path to grdlbuild log file>

Partitions that have not started vectorless power:
<partition 1>

Partitions that fail fsdb:
<partition 1>  <path to grdlbuild log file>

Partitions that are still running fsdb:
<partition 1>  <path to grdlbuild log file>

Partitions that have not started fsdb:
<partition 1>

Partitions that fail timebased power:
<partition 1>  <path to grdlbuild log file>

Partitions that are still running timebased power:
<partition 1>  <path to grdlbuild log file>

Partitions that have not started timebased power:
<partition 1>

number of partitions passing timebased power: <count>
mean total runtime all partitions passing timebased power: <00d:00h:00m:00s>

Top 5 fastest partitions with passing timebased power runs:
<total_runtime>  <partition 1>
<total_runtime>  <partition 2>
<total_runtime>  <partition 3>
<total_runtime>  <partition 4>
<total_runtime>  <partition 5>

Bottom 5 slowest partitions with passing timebased power runs:
<total_runtime>  <partition 1>
<total_runtime>  <partition 2>
<total_runtime>  <partition 3>
<total_runtime>  <partition 4>
<total_runtime>  <partition 5>

number of partitions passing vectorless power: <count>
mean total runtime all partitions passing vectorless power: <00d:00h:00m:00s>

Top 5 fastest partitions with passing vectorless power runs:
<total_runtime>  <partition 1>
<total_runtime>  <partition 2>
<total_runtime>  <partition 3>
<total_runtime>  <partition 4>
<total_runtime>  <partition 5>

Bottom 5 slowest partitions with passing vectorless power runs:
<total_runtime>  <partition 1>
<total_runtime>  <partition 2>
<total_runtime>  <partition 3>
<total_runtime>  <partition 4>
<total_runtime>  <partition 5>

total partitions that executed greater than one testname: <count>

Partitions that executed greater than one test in timebased run:
<partition1>
<partition2>
```

**Denominators:** elab: and vectorless: percentages divide by S20's full target
count (e.g. 146 -- every partition needs elab, and nearly all run vectorless).
fsdb: and timebased power: percentages divide by S23's timebased-eligible count
instead (e.g. 143, excluding partitions prep_pprtl2 found "not in mtl"/skipped).

**Action-required lists:** All pass/fail/running/not-started count blocks are
grouped together at the top (elab:/vectorless:/timebased:) so the whole run can
be scanned at a glance; the actual partition names that require action are
grouped together separately in a single "Action Required:" section further
down (partitions that Pass need no action, so they're never listed):
- "Partitions that fail <activity>:" -- one `<partition>  <path to grdlbuild log>`
  per line (the same log path used for status determination, S2).
- "Partitions that are still running <activity>:" -- same format (partition +
  grdlbuild log path).
- "Partitions that have not started <activity>:" -- bare partition names only
  (no log path exists yet since the grdlbuild log for that activity hasn't been
  created).
- If a category is empty, write a single line instead, e.g. "No partitions
  failed elab", "No partitions are still running elab", "No partitions have
  not started elab" (adjust wording per category/activity the same way).
- Repeat this pattern for all 4 activities, in this order: elab, vectorless
  power, fsdb, timebased power.

**Runtime stats (2026-08-16, see §6 Q27):** Right after the Action Required
section, for each of `timebased` then `vectorless` power (in that order):
- Only partitions whose `<power_mode>` `power_run_status` is `Pass` count --
  for timebased mode this means ONE entry per module (dedup), since fsdb/
  timebased-power runtime is module-level/shared across every test row of
  that module (§3.1); vectorless mode already has exactly one row per module.
- `<total_runtime>` is the SAME `elab+fsdb+power` sum used by compute.csv's
  `total_runtime` column (missing stages contribute 0, not excluded).
- "number of partitions passing <mode> power" is the count of those
  deduped/passing partitions; "mean total runtime..." is the mean of their
  `<total_runtime>` values, formatted `00d:00h:00m:00s` like every other
  runtime in this tool.
- Both the fastest-5 and slowest-5 lists are sorted ascending by
  `<total_runtime>` -- fastest-5 is the first 5 of the full ascending list;
  slowest-5 is the LAST 5 of that same ascending list (so within the
  slowest-5 block, the 5th-slowest partition is listed first and the single
  slowest partition is listed last -- ascending, not reversed). If fewer than
  5 partitions pass, the list(s) just show however many are available (may
  fully overlap between fastest/slowest if there are 5 or fewer total).
- If there are zero passing partitions for a mode, skip straight to a single
  line: "No runtime datapoints for timebased power (no passing runs)" (or
  "...vectorless power...") instead of the 4 sub-sections for that mode.

**Note: If no partitions executed greater than one test in the timebased run, then write "No Partitions Executed Greater Than One Test" in the corresponding section.**


## 3.4 report_pprtl2.compute.csv

**Description:** This file contains machine-readable data for each pprtl2 target stage, including cell count, runtime, and memory usage.

**Format:** CSV with the following columns:

```csv fields
module
power_mode  # vectorless or timebased
test_name   # example:  d2d_opt_i2c_high_3R1W_C2M_MCR_HIGH_25ww20a_525g01; "default" for vectorless (there's no real test name for vectorless mode -- see §6 Q24)
instance    # RTL instance path component under the test (e.g. "d2d_1_d2d1");
            # blank for vectorless. Real timebased runs key their reports/logs
            # by <test_name>/<instance>, and a test_name can have >1 instance,
            # so this is needed for row uniqueness -- not redundant with test_name.
elab_run_status   # Pass,  Fail=3, Running, Not Started
fsdb_run_status   # Pass,  Fail=-314, Running, Not Started, Not Required
power_run_status  # Pass,  Fail=2, Running, Not Started
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
test_name  (example:  d2d_opt_i2c_high_3R1W_C2M_MCR_HIGH_25ww20a_525g01; "default" for vectorless)
instance   (see 3.4 -- blank for vectorless, needed for timebased row uniqueness)
elab_run_status   # Pass,  Fail=3, Running, Not Started
fsdb_run_status   # Pass,  Fail=-314, Running, Not Started
power_run_status  # Pass,  Fail=2, Running, Not Started
untraced_sequentials_percentage    # <partition>.rtl_metrics.hier.csv  Calculated as `(sequential_cell_count / (register_cell_count+sequential_cell_count)) * 100`
annotation_primary_io   # blank for vectorless, filled for timebased  <partition>.stat2.rpt  "Primary I/P annotation:" -- percentage number ONLY, e.g. "4,075(96.75%)" -> 96.75
annotation_bb           # blank for vectorless, filled for timebased  <partition>.stat2.rpt  "Black Box annotation:" -- percentage number ONLY (same extraction)
annotation_seq          # blank for vectorless, filled for timebased  <partition>.stat2.rpt  "Sequential annotation: " -- percentage number ONLY (same extraction)
CGR                     # <partition>.rtl_metrics.hier.csv  "CGR (%)"
CGE                     # <partition>.rtl_metrics.hier.csv  "CGE (%)"
DACGE                   # <partition>.rtl_metrics.hier.csv  "DACGE (%)"
cell_count              # <partition>.rtl_metrics.hier.csv  "All Cell Count"
combinational_cell_count     # <partition>.rtl_metrics.hier.csv  "Combinational Cell Count"
unclocked_sequential_cell_count   # <partition>.rtl_metrics.hier.csv  "Sequential Cell Count"
register_cell_count     # <partition>.rtl_metrics.hier.csv  "Register Cell Count"
register_bit_count      # <partition>.rtl_metrics.hier.csv  "Register Bit Count"
flop_cell_count         # <partition>.rtl_metrics.hier.csv  "Flop Cell Count"
mbflop_cell_count       # <partition>.rtl_metrics.hier.csv  "MBFlop Cell Count"
eqfb                    # <partition>.rtl_metrics.hier.csv  "EQFB"
latch_cell_count        # <partition>.rtl_metrics.hier.csv  "Latch Cell Count"
mblatch_cell_count      # <partition>.rtl_metrics.hier.csv  "MBlatch Cell Count"
eqlb                    # <partition>.rtl_metrics.hier.csv  "EQLB"
VCS_VERSION             # S6 (elab/pprtl_work/vcs/vcs.log), 2nd line: "Version <VERSION> -- <date>"; trailing "_Full64" trimmed if present
VERDI_VERSION           # S2 elab grdlbuild log: "Info: VERDI_HOME = .../verdi3/<VERSION>"
PPRTL_VERSION           # S2 elab grdlbuild log: "Version: <VERSION> for linux64 - <date>"
```



**Finding register_bit_count, CGR, CGE, DACGE (updated 2026-08-12)**
- **register_bit_count/CGR/CGE/DACGE** all come from S25 (`<module>.rtl_metrics.hier.csv`)'s
  own top-of-hierarchy row -- the row where `Hierarchy Level` == "0" AND
  `Module Name` == the partition name (columns `Register Bit Count`,
  `CGR (%)`, `CGE (%)`, `DACGE (%)`). This wins over stat2.rpt for timebased
  mode too (§2 precedence, Q18). The old cge.hier.rpt source is retired.


**Calculating untraced_sequentials %**
- Always calculated: `(sequential_cell_count / (register_cell_count+sequential_cell_count)) * 100`,
  rounded to 2 decimal places, using the register/sequential cell counts from
  S25's own row. stat2.rpt's "Untraced Sequential ratio" field is no longer
  consulted (Q18) -- stat2.rpt now only supplies the 3 annotation fields.


**Extracting the 3 annotation fields (updated 2026-08-12, Q22)**
- stat2.rpt's raw values look like `<count>(<pct>%)`, e.g. `4,075(96.75%)` or
  `146(100%)` -- keep ONLY the percentage number (`96.75`, `100.0`), discarding
  the leading count. Regex: `\(([\d.]+)\s*%\)`, converted to float. Blank if
  the field is absent or doesn't match that shape.


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
  an entry; Not Started/Running/Pass-only partitions are omitted entirely.


## 3.7 report_pprtl2.README

```md
# report_pprtl2.README

## pprtl1 vs pprtl2 terminology
| Metric | PPRTL1 | PPRTL2 | Notes |
| % clock gated registers (static) | Static Clock Gating Efficiency (SCGE) | Clock Gating Ratio (CGR) | Static CGE is your upper bounds |
| % gated clock cycles; lacks correlation with data activity | Dynamic Clock Gating Efficiency (DCGE) | Clock Gating Efficiency (CGE) | |
| CGE +  [data toggle cycles / root clock cycles] | Data Aware Clock Gating Efficiency (DACGE) | Data Aware Clock Gating Efficiency (DACGE) | DACGE will be the same or higher than CGE/DCGE by nature of the arithmetic.|
| % untraced sequentials | - | Untraced Sequentials (%) | Calculated manually in pprtl1|
| Sequential Cell Count | sequential_cell_count from get_cells -filter \"is_sequential==true\"  | sequential+register power group |  Slightly different calculation method since some sequentials can sit in clock network |


## Report fields
- To see all attributes available in the RTL metrics, use the following in the pprtl2 shell:
  `report_rtl_metrics -list_attributes -view`
- EQFB: Total count of equivalent flop cells in the listed hierarchy
- EQLB: Total count of equivalent latch cells in the listed hierarchy
- EQFB+EQLB should be very close to register_bit_count
```

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
- grdlbuild netbatch job log (`output/grdlbuild_power/logs/power.<module>.pprtl2_<activity>.log`,
  `<activity>` = elab/fsdb/power_vectorless/power_timebased) is now the SOLE
  ground truth for status (2026-08-11 decision, see Q11): header line matches
  `Logfile\s*:`; footer (only once the job finishes) has `Exit Status`,
  `WC <fmt>` (format varies: `3h:00m:37s` with no days, or `1d:14h:47m:11s`
  with days -- parse flexibly), and `Rusage Stats ... Mem:<n>` where **n is in
  MEGABYTES** (user-confirmed; convert to GB via `n / 1000`, decimal not
  binary). A module with BOTH vectorless and timebased modes gets FOUR
  separate grdlbuild logs (elab/fsdb/power_vectorless/power_timebased), not a
  single shared `pprtl2_power.log` as earlier assumed.
- `elab/log/flow.log` (and the fsdb/vectorless/timebased equivalents) ALWAYS carry
  `Maximum memory usage for this session: ... KB (X.XX GB)` and
  `Elapsed time for this session: N seconds` near the end when the stage finished,
  regardless of grdlbuild use (grdlbuild just wraps `make elab/power`). This is
  now a runtime/memory FALLBACK only (§3.2) -- flow.log plays no part in
  Pass/Fail/Running/Not-Started determination since 2026-08-11 (Q11).
- `prep_pprtl2_report.summary` (S19) format CHANGED (2026-08-11): no more
  "ran : N (P%)" line -- now has `total partitions : N`, `vectorless/timebased
  setup generated/skipped`, `missing 2stage/hiplist/clocks`, `timebased not in
  mtl`, `timebased fsdb missing`, etc. Only "total partitions" is still parsed;
  the old "pre-flight pass" summary.md line was removed entirely (Q14) since
  there's no longer a single "ran" concept to map it to.
- `prep_pprtl2_partition.list` (S20) and the NEW `prep_pprtl2_timebased_partition.list`
  (S23) are two DIFFERENT target lists: S20 is the full vectorless+elab target
  set (e.g. 146); S23 is the timebased-eligible SUBSET (e.g. 143, excluding
  partitions prep_pprtl2 found "not in mtl"). elab:/vectorless: sections use
  S20 as denominator; fsdb:/timebased power: sections use S23 (Q13).
- REF_MODEL/SDC_ARCHIVE under `power/pprtl2/` are designer-made symlinks; the
  summary.md must print the resolved TARGET path (`Path.resolve()`), not the
  symlink's own path. `MTL_FILE` (S24, new 2026-08-11) gets identical
  treatment (Q15).
- `elab/pprtl_work/sdc/read_sdc.log` (S21) exists at that exact path for every
  module that reached elab, regardless of power mode.
- A dual-mode partition's `flow_inputs/config.log` (S1) is APPENDED TO once per
  stage invocation (elab, then fsdb, then power_vectorless, then
  power_timebased), so it holds multiple stacked table blocks with
  alternating `POWER_ANALYSIS_MODE` values -- don't trust this field to infer
  mode when both modes are present; use on-disk `power/vectorless` +
  `power/timebased` dir presence instead.
- fsdb and timebased-power are each exactly ONE grdlbuild task per module,
  covering every timebased test in that single job (confirmed: log file counts
  matched module counts, not test-instance counts) -- so their StageResult is
  computed ONCE per module and shared across every test-name row of that
  module, unlike per-test QoR data which still varies per test (Q16).
- `output/grdlbuild_power/logs/tasks_summary.log` (S22) exists when grdlbuild was
  used and gives clean per-module-per-stage `Task Path: :power:<module>:pprtl2_<stage>`,
  `Task Status: Success/Failed/Skipped`, `Exit Status`, `Run Time` -- still NOT
  consumed by this tool (see §9 Non-goals); the raw per-activity grdlbuild log
  parsing (S2) is used directly instead.

- **Q1** Should module identity/grouping use path segments or config.log? --
  Use `TOP_MODULE_NAME` from S1; group all discovered pass-dirs by it and pick the
  newest (by directory mtime) per module.
- **Q2** How to parse config.log? -- As the ASCII table it actually is (see above),
  not key=value.
- **Q3** Flat vs. nested fsdb paths? -- Nested per test+instance (see above).
- **Q4** Is grdlbuild's `tasks_summary.log`/`failure_tasks_summary.log` (S22) a
  better primary source for per-module-per-stage status/runtime than raw log
  parsing? -- Investigated and offered twice (2026-07-26 and 2026-08-11); user
  declined both times, preferring the raw per-activity grdlbuild log (S2)
  parsed directly. Kept as a documented, not-yet-implemented option (§9).
- **Q5** Netbatch Rusage "Mem" field unit? -- Megabytes (user-confirmed from a
  real example: `Mem:183730` == "183.730 GB" after `/1000`).
- **Q6** Is the `partition/<module>/pprtl2/<pass>/` layout still needed? -- Yes,
  confirmed with a real example (`corhub_oks-a0-pprtl2-partitions-3`); the
  2026-08-11 real dual-mode workarea (`dmrhub2-a0-corioh-pprtl2-partitions-1`)
  in fact uses ONLY this layout, not the flat one.
- **Q7** Should `report_pprtl2.compute.csv`/`.qor.csv` cover every S20 partition,
  even ones that never reached elab or power? -- Yes (found via a real discrepancy:
  184 S19 total / 181 S20 pre-flight-pass vs. only 170 CSV rows in a real workarea;
  12 modules had elab `Fail=2` and no `power/` dir at all and were silently
  dropped). Fixed by iterating `set(S20) | set(discovered)` and emitting a
  fallback row (`Not Started` for stages never reached) for every target module.
- **Q8** Keep the spec's original "Skipped" status? -- No, removed entirely
  (2026-07-26 decision, reversing an earlier plan to detect it via
  `SKIP_STAGES`). Only Pass/Fail=&lt;n&gt;/Fail/Running/Not Started/Not Required are
  used; disambiguating *why* something is `Not Started` is deferred.
- **Q9** Should REF_MODEL/SDC_ARCHIVE show the symlink path or its target? --
  The resolved target (see above).
- **Q10** Should the `TOP_IP_NAME` line stay in summary.md? -- No, removed
  (2026-07-26); replaced by two coverage stat lines (grdlbuild-log coverage,
  flow.log coverage) that turned out to be more broadly useful.
- **Q11** (2026-08-11) Should grdlbuild-only Pass/Fail/Running/Not-Started
  status REPLACE the richer per-row logic (grdlbuild-footer-then-flow.log,
  `.PASS`-marker-aware) everywhere, or only power the new summary.md aggregate
  section? -- Replace EVERYWHERE (compute.csv/qor.csv/fail.details too).
  `.PASS` marker files (S3/S8/S9) are no longer consulted for status at all --
  they remain on disk but are historical artifacts only. Known limitation:
  workareas that never used grdlbuild (e.g. `dmrhub2-a0-pprtl-statecount`,
  which used `nb_logs/` instead) will now show every stage as `Not Started`
  even if the row actually completed via direct `make` invocation. Accepted as
  a known limitation since grdlbuild is the standard flow going forward (§9).
- **Q12** Rename the grdlbuild power log from a single shared
  `pprtl2_power.log` to mode-specific `pprtl2_power_vectorless.log`/
  `pprtl2_power_timebased.log`? -- Yes, confirmed on real dual-mode data; this
  also resolves the earlier documented ambiguity about which mode a shared
  power log's exit code belonged to.
- **Q13** Which target list is the denominator for each summary.md section? --
  elab:/vectorless: use S20 (full target list, e.g. 146); fsdb:/timebased
  power: use the NEW S23 timebased-eligible subset (e.g. 143). Confirmed by a
  real annotation ("this should be the vectorless partition count") that only
  made sense once S20 vs. S23 was understood.
- **Q14** What replaces the old "total partitions pass pre-flight" line since
  S19 no longer has a "ran" line? -- Removed entirely; superseded by the new
  elab:/vectorless:/timebased: pass/fail/running/not-started breakdown.
- **Q15** Omit the MTL_FILE line when absent (like the tool's own §3.3
  "if it was set and exists" wording implies), or print "NA" like
  REF_MODEL/SDC_ARCHIVE? -- Print "NA" for consistency with REF_MODEL/SDC_ARCHIVE.
- **Q16** Should fsdb/timebased-power status vary per test-name row (since
  each test could theoretically pass/fail independently), or be shared across
  all of a module's timebased rows? -- Shared: real grdlbuild log file counts
  confirmed fsdb/power_timebased are each ONE task per module (not per test),
  so per-test independence never existed at the grdlbuild-truth level anyway.
- **Q17** (2026-08-11) Add per-activity action-required partition lists (fail/
  running/not-started, with grdlbuild log paths) to summary.md? -- Yes. First
  tried interleaving each activity's action lists right after its own count
  block, but the user reversed this: all pass/fail/running/not-started count
  blocks (elab:/vectorless:/timebased:) are grouped together at the top for a
  quick full-run scan, and all 4 activities' action-required lists are grouped
  together in one "Action Required:" section further down.
- **Q18** (2026-08-12) Does `<module>.rtl_metrics.hier.csv` (S25) replace the
  old cells.rpt/cge.hier.rpt/power_groups.rpt sources, and does it win over
  stat2.rpt's overlapping fields too? -- Yes to both: S25 is now the primary
  (and only) source for cell_count/register_cell_count/sequential_cell_count/
  register_bit_count/CGR/CGE/DACGE/flop_cell_count/mbflop_cell_count/eqfb/
  latch_cell_count/mblatch_cell_count/eqlb, for vectorless AND timebased mode.
  stat2.rpt's only remaining job is the 3 timebased annotation fields
  (primary_io_annotation/bb_annotation/seq_annotation); its "Untraced
  Sequential ratio" field is no longer read -- untraced_sequentials is always
  calculated manually from S25's register/sequential cell counts.
- **Q19** (2026-08-12) Keep cells.rpt/cge.hier.rpt/power_groups.rpt as a
  fallback for modules/older runs missing rtl_metrics.hier.csv? -- No, retired
  entirely (`parse_power_groups`/`parse_cge_hier_module_row` removed from the
  code); a module missing S25 or its own hierarchy row just gets blank QoR
  fields, same as any other unavailable metric.
- **Q20** (2026-08-12) VCS_VERSION/VERDI_VERSION/PPRTL_VERSION -- where do
  they belong, and what if the underlying log is missing? -- qor.csv only
  (not compute.csv), repeated on every row of a module (they're module-level:
  one elab run per module regardless of power mode, same pattern as
  elab_run_status). Blank when vcs.log/the elab grdlbuild log is unavailable
  or the expected line isn't found, consistent with how every other qor.csv
  field behaves when its source is missing.
- **Q21** (2026-08-12) Performance: rtl_metrics.hier.csv can have 10000+
  hierarchy rows -- read the whole file every time? -- No: the parser
  (`parse_rtl_metrics_hier_csv`) stops and returns as soon as it finds the
  module's own top-of-hierarchy row (`Hierarchy Level` == "0"), never reading
  or parsing the rest of the file. Verified against real data: this row is
  always the first data row after the header on disk, so in practice the
  parser reads a single row per file, not the full hierarchy.
- **Q22** (2026-08-12) VCS_VERSION/annotation field cleanup: trim VCS_VERSION's
  trailing `_Full64` suffix, and keep only the percentage number from the 3
  stat2.rpt annotation fields (e.g. `4,075(96.75%)` -> `96.75`). Both
  implemented as simple post-extraction transforms (`str.endswith`/slice for
  the suffix; `\(([\d.]+)\s*%\)` regex for the percentage) -- no change to
  which source file each value comes from.
- **Q23** (2026-08-12) Confirmed multiple timebased test-name directories
  directly under `power/timebased/` (e.g. `power/timebased/test1/`,
  `power/timebased/test2/`, the user's exact hypothetical layout) are handled
  correctly: `build_rows()` already discovers every test-name subdirectory
  under `power/timebased/` (not just multiple instances within one test) and
  emits one row per (test_name, instance), sharing module-level elab/fsdb/
  timebased-power status. Verified via a dedicated synthetic-tree smoke test
  matching the user's exact layout, in addition to the pre-existing
  `test_timebased_module_with_two_tests_shares_module_level_fsdb_power_status`
  unit test.
- **Q24** (2026-08-12) Should vectorless rows' `test_name` stay blank (there's
  no real test name in vectorless mode) or get a placeholder? -- Set to
  `"default"` (matches the literal `default` directory name vectorless mode
  already uses on disk, e.g. `power/vectorless/default/reports/`). Only the
  vectorless row-creation call site in `build_rows()` changed; the timebased
  fallback row for a target with no test dirs discovered yet still gets `""`
  (there's no real or placeholder test name to give it).
- **Q25** (2026-08-14) qor.csv field cleanup/additions and file renames (user
  edited the spec directly, then asked to reconcile the implementation):
  added `combinational_cell_count` (S25 "Combinational Cell Count"); renamed
  `sequential_cell_count`->`unclocked_sequential_cell_count`,
  `untraced_sequentials`->`untraced_sequentials_percentage`,
  `primary_io_annotation`->`annotation_primary_io`,
  `bb_annotation`->`annotation_bb`, `seq_annotation`->`annotation_seq`;
  renamed `report_pprtl2.summary.md`->`report_pprtl2.summary` and
  `report_pprtl2.terminology.md`->`report_pprtl2.README` (content restructured
  per the new §3.7, incl. a 4th "Notes" table column and a new "Sequential
  Cell Count" terminology row). Internal `Config` properties/constant were
  renamed to match (`summary_md`->`summary`, `terminology_md`->`readme`,
  `TERMINOLOGY_MD`->`README_MD`) via safe workspace-wide symbol rename, since
  keeping Python names tied to an old file extension would be misleading.
  The generated `report_pprtl2.README`'s content starts directly at the
  "## pprtl1 vs pprtl2 terminology" heading -- the §3.7 fenced block's leading
  "# report_pprtl2.README"/"**Description:**"/"Write direct output, no
  processing." lines are spec narration (consistent with every other output
  section in this doc), not literal file content.
- **Q26** (2026-08-14) Reversed part of Q25: add a `# report_pprtl2.README`
  title line (+ blank line) to the top of the actual generated file after
  all, so it stays unchanged; the "**Description:**"/"Write direct output, no
  processing." lines remain spec narration only, not written to the file.
- **Q27** (2026-08-16) Added a runtime-stats section (count/mean/fastest-5/
  slowest-5) to summary.md, right before the multi-testname section, for
  timebased then vectorless power. Confirmed via clarifying Q&A: (1) rank/
  average by `<total_runtime>` = elab+fsdb+power summed (compute.csv's
  `total_runtime`), not just the power stage's own runtime; (2) the
  slowest-5 list is ascending WITHIN the list too (5th-slowest first,
  slowest last), not reversed/descending; (3) `<total_runtime>` and
  `<partition>` are separated by a double space, matching the existing
  Action-Required list style. Only partitions whose `<mode>` power passed
  count, deduped by module for timebased (module-level shared runtime across
  test rows, §3.1) -- vectorless already has 1 row/module. Verified against
  `dmrhub2-a0-corioh-pprtl2-partitions-y-without_ld` (136/140 passing
  timebased/vectorless partitions; sensible ascending fastest/slowest-5 lists
  and means).

---

## 7. Test plan

Implemented in `scripts/pprtl2/test_report_pprtl2.py` (68 tests, table-driven,
zero live-tool/disk dependency beyond `tempfile.TemporaryDirectory`):

1. **Unit -- input/report-file parsing:** `TestConfigTableParsing`,
   `TestReportParsers`, `TestVersionInfo`, `TestNetbatchAndFlowLogFooters`,
   `TestGrepContextBlocks`, `TestSymlinkTarget`, `TestReadPartitionList` -- each
   pure parser gets fixture text (copied verbatim from real files) and asserts
   the extracted fields, including precedence/edge cases (first-key-wins,
   missing file, no matches, adjacent vs. distant grep windows, and
   `parse_rtl_metrics_hier_csv`'s stop-at-first-matching-row behavior).
2. **Unit -- per-activity status logic:** `TestEvaluateStage` -- Pass/Fail=&lt;n&gt;
   (grdlbuild footer Exit Status), Running (grdlbuild log present, no footer
   yet), Not Started (no grdlbuild log at all), flow.log filling in
   runtime/memory only when the grdlbuild footer is missing them.
3. **Unit -- QoR precedence:** `TestQorExtraction` -- rtl_metrics.hier.csv (S25)
   as the primary source for both vectorless and timebased mode (winning over
   stat2.rpt's overlapping fields per the updated §2 precedence rule), stat2.rpt
   supplying only the timebased annotation fields, and blank fields when S25 is
   missing/the module's row isn't found.
4. **Integration -- discovery + row assembly:** `TestBuildRows` -- builds a fake
   on-disk tree (both output layouts, vectorless and timebased-with-2-tests,
   newest-pass-dir selection, elab-only/no-power-dir fallback rows, never-
   discovered ghost modules, module-level fsdb/timebased-power sharing across
   test rows, S20/S23 target-list-driven row production, VCS_VERSION/
   VERDI_VERSION/PPRTL_VERSION propagating into every row's qor dict for a
   module) and asserts the resulting `Row`/`ModuleStatus` data end-to-end.
5. **Integration -- CLI/pre-flight/main():** `TestPreflightAndCli` -- every
   `preflight()` failure mode, `resolve_config()`'s `$WORKAREA` fallback and
   missing-workarea error, and `main()`'s exit codes (2 for pre-flight failure,
   2 for zero discovered rows, 0 for `--dry-run` writing nothing, 0 for a full
   run writing all 5 files).
6. **Integration -- report writers:** `TestCsvAndReportWriters`,
   `TestRenderSummaryMd`, `TestGenerateReports` -- CSV headers/rows, summary.md's
   command-line/MTL_FILE/count+percent lines, the new elab:/vectorless:/
   timebased: pass/fail/running/not-started sections (incl. the S20-vs-S23
   denominator split, the per-activity action-required partition+log-path lists,
   and their empty-category fallback wording), the timebased/vectorless
   runtime-stats section (count/mean/ascending fastest-5/slowest-5, module-level
   dedup for timebased, and the no-passing-runs fallback line) and the
   no-multi-test fallback note, fail.details' per-module grouping and
   log-block grep windows, and `generate_reports()`'s all-5-files-written
   contract.
7. **Smoke (manual, not automated):** run against the real workareas above and
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
- **Phase 5 (2026-08-11):** ✅ **DONE** -- dual vectorless+timebased real-world
  workarea support: MTL_FILE (S24), S23 timebased-eligible target list,
  grdlbuild-only Pass/Fail/Running/Not-Started status everywhere (replacing
  `.PASS`-marker/flow.log-text heuristics), mode-specific grdlbuild power logs,
  module-level fsdb/timebased-power sharing, and the restructured
  elab:/vectorless:/timebased: summary.md sections. Smoke-tested against
  `dmrhub2-a0-corioh-pprtl2-partitions-1` (146 partitions, both power modes,
  grdlbuild in active use with real Pass/Fail/Running/Not-Started rows).

---

## 9. Non-goals

- **Orchestrating pprtl2 runs.** This tool only reads an existing run area; it
  never invokes `pprtl`, `grdlbuild`, `make elab/power`, etc. (see §1's
  non-destructive-to-sources guarantee).
- **S22 (`tasks_summary.log`) consumption.** Identified as a source and
  considered as a simpler status/runtime alternative (§6 Q4), but not adopted or
  implemented -- the raw per-activity grdlbuild log (S2) is parsed directly
  instead. Revisit if per-module log parsing ever proves unreliable in practice.
- **Disambiguating *why* a stage is `Not Started`** (never attempted vs. blocked by a
  failed dependency vs. intentionally skipped). Deferred per §6 Q8.
- **Non-grdlbuild workareas.** Since 2026-08-11 (§6 Q11), status is grdlbuild-log-only
  everywhere; a workarea that never used grdlbuild will show every stage as
  `Not Started` regardless of whether it actually completed via a direct `make`
  invocation. Accepted as a known limitation since grdlbuild is the standard flow.
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
