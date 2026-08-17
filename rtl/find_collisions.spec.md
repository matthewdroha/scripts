# Spec: `find_collisions` — Identify and report rtl library collisions in a design database. 

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
  - scripts/rtl/find_collisions.spec.md   (this file — a single-input, streaming-XML
    report tool over a 14.6 GB / 16M-element real dump; a report deliberately
    FILTERED to an anomaly subset (colliding modules only) rather than a full
    inventory, a fast no-parse `--dry-run`, and stdlib-only large-file streaming
    via `iterparse` + periodic root-clearing.)

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

Status: **DONE** — Phase 5 (2026-08-13): implemented, 34 unit tests pass, smoke-tested
against a real config_diagnostics.xml slice.
Owner: mroha
Language: Python 3 (stdlib, plus `openpyxl` for the .xlsx workbook -- see §3.4)
Scope: Using the VCS elaboration XML dump, detect potentially problematic cases where RTL has multiple different definitions
Implementation: scripts/rtl/find_collisions.py (+ scripts/rtl/test_find_collisions.py)

---

## 1. Purpose

This tool analyzes the VCS elaboration XML dump to detect potentially problematic cases where RTL has multiple different definitions. It generates both machine-readable and human-readable reports to help engineers quickly identify and resolve such collisions. The tool collates data from the XML dump, applies per-item derivation rules, and produces comprehensive reports that facilitate further analysis.

State the two properties most automation should guarantee:

- **Generative & idempotent:** re-running reproduces the same output tree from the
  same inputs.
- **Non-destructive to sources:** it does not modify its inputs.

---

## 2. Inputs (sources of truth)

List every input as a numbered source so the rest of the doc can reference `S1`, `S2`, …
Include the *exact* path shape and any auto-detection/selection rule.

--xml <path to VCS elaboration XML dump>

This file may be gzipped    (e.g., `elaboration.xml.gz`).



| # | Source | Provides | Notes (exact paths, selection rules, gotchas) |
|---|--------|----------|-----------------------------------------------|
| S1 | config_diagnostics.xml(.gz) | VCS elaboration dump  | Contains a map of instance-definition relationships for the RTL design hierarchy.  This file can be quite large. |

**Verified on disk (2026-08-12):** a real `config_diagnostics.xml.gz` is 174 MB
compressed / 14.6 GB uncompressed, 16,269,991 `<Instance>` elements. gzip vs.
plain is detected by magic-byte sniffing (`\x1f\x8b`), not by file extension,
so a `.gz`-suffixed-but-plain (or vice versa) file still works.

<!-- Tip: where a real input layout varies between targets, prefer AUTO-DETECT
     (probe the disk) over hardcoding, and record the observed variants. -->


---

### 2.1 Pre-flight validation (fail fast)

**Checks:**
- Existence of input xml file specified by --xml argument

---

## 3. Outputs (the generated tree)

Output root is CWD

```
<output_root>/
└── find_collisions.csv                       # Machine-readable, collisions-only module definition report (see §3.1)
└── find_collisions.minimized.csv             # Per module+source collision rollup (see §3.2)
└── find_collisions.minimized.realpath.csv    # §3.2 with source realpath-collapsed (see §3.3)
└── find_collisions.xlsx                      # All 3 reports as Excel Table sheets (see §3.4)
```


## 3.1 find_collisions.csv
**Description:** This file contains a machine-readable report of the RTL modules that
actually **collide** — i.e. the same module name is bound to more than one distinct
(library, configrule, source) combination somewhere in the design. Modules with
exactly one definition (the overwhelming majority — verified 71,553 of 73,882 real
modules) are **not** included; only the colliding module's rows (all of its distinct
definitions) are written. See §4 for the exact collision rule and §6 Q1/Q2.


**Format:** CSV with the following columns:

```csv fields
module               # Name of the RTL module.  XML:  <Module > inside of the  <DefinitionDetails > section
library              # Name of the library bound to the RTL module.  XML:  <Library > inside of the  <DefinitionDetails > section
configrule           # Configuration rule applied to the RTL module.  XML:  <Rule > inside of the  <ConfigRule > section
source               # Full source file for the RTL module and linenumber  XML:  <SourceInfo > inside of the  <DefinitionDetails > section
instance_count       # Number of instances that are bound to this specific module+library+configrule+source key
```

Header is always written, even when there are zero collisions (empty report is a
valid, meaningful result: the design has no colliding definitions).

---

## 3.2 find_collisions.minimized.csv
**Description:** A per-`module+source` rollup, but with a **stricter** qualification
rule than find_collisions.csv (§3.1): a module only appears here if it has more
than one **distinct source** (a genuinely different underlying file/line) --
not merely a different library or configrule label bound to the identical
source (see §6 Q7; that's `>1` for §3.1 but does NOT qualify here). Where
find_collisions.csv's unique key is the full module+library+configrule+source
4-tuple, this file collapses library and configrule out of the key so a
reviewer can see, for one specific module definition file:line, how many
*different* libraries/configrules it was bound to -- without being distracted
by modules whose only "difference" is a library/configrule label on one
physical file.

**Format:** CSV with the following columns:

```csv fields
module                 # Name of the RTL module
source                  # Full source file for the RTL module and linenumber (same text as §3.1's source column)
library_count           # Number of DISTINCT libraries bound to this module+source pair
config_rule_count       # Number of DISTINCT config rules bound to this module+source pair
instance_count          # Total number of instances bound to this module+source pair (summed across all library/configrule combos)
<configrule value>      # One column PER DISTINCT configrule value found ANYWHERE in the whole XML (see §6 Q8) --
                        # e.g. "default library search order", "parent cell's library". Value is 1 if that
                        # configrule was one of the ones bound to this module+source pair, else 0. A column is
                        # added even if that configrule value never appears among the qualifying rows themselves.
                        # sum(these columns) == config_rule_count for every row.
```

Unique key: `module+source`. Header is always written, even when there are zero
collisions.

---

## 3.3 find_collisions.minimized.realpath.csv
**Description:** Same shape/columns/qualification rule as §3.2 (>1 DISTINCT
SOURCE required), but the `source` path is resolved via `os.path.realpath`
BEFORE that distinct-source check, so two textually different but
real-file-equivalent paths (differing only in their `../../..`-style relative
traversal, or resolved through a symlink) are treated as the **same** source.
This exists specifically to remove false-positive collisions like
`arf044b032e1r1w0cbbehraa4acw_clk`, which appeared to collide only because its
two instantiating callers used different relative-path spellings that both
resolve to the identical absolute file:line. A module that no longer has more
than one distinct realpath-canonicalized source after this collapse is
**dropped entirely** (§6 Q6/Q7). This report can therefore only have the
**same or fewer** rows/modules than §3.2, never more.

**Format:** identical columns to §3.2, including the same per-configrule 1/0
columns (`module,source,library_count,config_rule_count,instance_count,
<configrule value>...`); `source` here is the canonicalized
`"<realpath>",<linenum>` string. Same sort order (module ascending, then
`instance_count` descending). Header always written. The configrule column
set is the SAME whole-XML universe as §3.2 (computed once from the raw,
pre-canonicalization counts) -- canonicalizing `source` never changes which
configrule values exist in the design.

---

## 3.4 find_collisions.xlsx
**Description:** A single Excel workbook with 3 sheets, one per CSV above
(§3.1/§3.2/§3.3), so a reviewer can browse/sort/filter all three reports
without opening separate CSVs. Sheet names: `collisions`, `minimized`,
`minimized_realpath`. Each sheet's header+data range is wrapped in a native
Excel Table object (not just a styled range) so Excel's built-in sort/filter/
totals-row UI works immediately. Header row is always written, even for a
sheet with zero data rows (Table object spans just the header row in that
case). Requires the `openpyxl` package (not stdlib -- see §6 Q8).


## 4. Per-item derivation rules

- Each `<Instance>` in the XML contributes one (module, library, configrule, source)
  tuple (from its `<DefinitionDetails>` + `<ConfigRule><Rule>`); `instance_count` is
  the number of instances sharing that exact 4-tuple.
- **Collision rule:** group tuples by `module` name. A module is a collision if it
  has **more than one** distinct (library, configrule, source) combination — i.e.
  differing in **any** of the three fields counts (a same-library/same-source module
  bound via two different configrules is still a collision). Non-colliding modules
  (exactly one distinct combination, regardless of instance_count) are omitted
  entirely from the report.
- Only colliding modules' rows are written to find_collisions.csv; every distinct
  combination for that module is written (not just the majority/minority one).
- **Row order:** module name ascending, then `instance_count` descending within a
  module (puts each collision's most-common definition first).
- The design's single top-level instance (XML `<TopDetails>` instead of
  `<InstanceDetails>`) is treated identically to every other instance — it
  contributes a tuple the same way and can, in principle, participate in a
  collision (real designs won't collide on the top module, but no special-casing
  is applied).
- **find_collisions.minimized.csv derivation:** a module qualifies only if it has
  more than one **distinct source** (see §6 Q7) -- a library/configrule-only
  difference on an identical source does NOT qualify here, even though it does
  for §3.1's `colliding_modules()` rule. For each qualifying module, group its
  (library, configrule, source) tuples by `source`; `library_count`/
  `config_rule_count` are the counts of DISTINCT libraries/configrules seen for
  that `module+source` pair, and `instance_count` is the sum of `instance_count`
  across every (library, configrule) combo sharing that `module+source`. Row
  order: module name ascending, then `instance_count` descending within a
  module.
- **find_collisions.minimized.realpath.csv derivation:** re-key the ORIGINAL
  4-tuple counts by replacing `source`'s path with `os.path.realpath(path)`
  (keeping the line number), summing instance counts of tuples that collapse to
  the same (module, library, configrule, canonical_source) key; only tuples
  belonging to a module already in §3.1's colliding set need re-keying
  (canonicalizing can only MERGE distinct combinations, never split them, so a
  module that wasn't colliding before cannot become colliding after -- this
  keeps the number of `realpath()` filesystem calls bounded to already-flagged
  modules, not every one of the ~78K+ real combos -- and remains a valid
  performance pre-filter even though §3.2/§3.3's own qualification rule is the
  stricter distinct-source one, since a distinct-source module is always a
  subset "of a colliding one). The §3.2 distinct-source rule is then re-applied
  to this re-keyed data (via the same `modules_with_multiple_sources()`/
  `collect_minimized_rows()` helpers) -- a module drops out entirely if it no
  longer has more than one distinct canonical source.
- Both minimized reports are derived from a **single** pass over the XML (one
  shared in-memory `Counter` of 4-tuple instance counts) -- the file is never
  streamed twice in one run.
- **Per-configrule columns (§3.2/§3.3, §6 Q8):** the set of extra columns is
  every DISTINCT configrule value found anywhere in the raw (whole-XML,
  pre-filter) counts -- `all_configrule_values()`, sorted alphabetically for a
  stable column order -- NOT just the configrule values that happen to appear
  among the qualifying/colliding rows. Both §3.2 and §3.3 use this SAME column
  set (computed once, from the original counts). For each row, a column's
  value is 1 if that configrule was one of the DISTINCT configrules bound to
  that row's `module+source` pair (the same set backing `config_rule_count`),
  else 0 -- so `sum(these columns) == config_rule_count` always holds.
- **find_collisions.xlsx derivation (§3.4):** one workbook, one sheet per CSV
  above, each sheet's full header+data range wrapped in an Excel Table object.
  Built from the exact same in-memory rows/fieldname lists used to write the
  three CSVs (no separate derivation/second pass).

---

## 5. CLI

```
find_collisions.py \
  --xml         <xml file>        # may be gzipped (auto-detected by magic bytes, not extension). Will be large
  [--dry-run] [--force] [--verbose]
```

Conventions (recommended for all automation):
- `--dry-run` — print the plan (all four output paths), write nothing, and
  **do not parse the XML** (parsing the full real file is itself the slow part;
  a dry run should stay fast).
- `--force` — this is a pure REPORT-generating tool: all outputs are always
  regenerated/overwritten every run. `--force` is accepted for CLI parity but is a
  no-op here.
- `--verbose` — log progress every 1,000,000 `<Instance>` elements processed (the
  real file has 16M+), plus the final instance count and each report path once written.
- Output root is always CWD (no `--outdir`/`--workarea`; this is a standalone,
  single-input tool, not tied to a workarea).
- Validate all inputs before writing any output (fail fast).

---

## 6. Decisions log (resolved questions & notes)

**Verified on disk (2026-08-12)**, against
`/nfs/site/disks/dmr_fe_mod_0012/dmrhub2/dmrhub2-a0-corioh-26ww27a/output/ioh/vcs/h2b_v2k/vcs_elab/config_diagnostics.xml.gz`:
- 174 MB compressed / 14.6 GB uncompressed; 16,269,991 `<Instance>` elements.
- Structure per `<Instance>`: exactly one `<TopDetails>` (only the single design-top
  instance) **or** `<InstanceDetails>` (every other instance) -- neither is needed
  by this tool; exactly one `<DefinitionDetails>` (`<Module>`/`<Library>`/
  `<SourceInfo>`) and exactly one `<ConfigRule><Rule>` per instance, always.
  `<InstanceArray />` (empty tag) appears on 149,447 instances (array
  instantiations) -- irrelevant to collision detection, not read.
- No XML declaration; tags pretty-print with a trailing space before `>` (e.g.
  `<Module >x</Module >`) -- both are ordinary well-formed XML, parse unmodified
  with `xml.etree.ElementTree`.
- `<SourceInfo>` text is the literal `"<path>",<linenum>` string (quote-wrapped
  path + comma + line number) -- written to the `source` column verbatim; the
  embedded comma/quotes are handled by Python's `csv` module's normal quoting
  (`"""/path..."",5"` on disk), not by any manual escaping in this tool.
- Real-data scale check: 73,882 distinct module names, 78,292 distinct
  (module, library) pairs, 2,329 modules bound to more than one library (i.e.
  collisions are common enough that filtering the report to collisions-only is
  worth doing rather than dumping a ~78K+ row full inventory).

**Q1 (collision filtering):** Should find_collisions.csv list every unique
module+library+configrule+source combo (full inventory), or only modules that
collide? **ANSWER:** filter to collisions only -- a module is included only if it
has more than one distinct (library, configrule, source) combination.

**Q2 (collision definition):** Does a difference in configrule alone (same
library+source) count as a collision, or only library/source differences?
**ANSWER:** any of the 3 fields differing counts as a collision.

**Q3 (sort order):** **ANSWER:** module name ascending, then instance_count
descending within a module.

**Q4 (performance approach):** given the real file's size (14.6 GB / 16.27M
instances), is a pure-Python streaming parse acceptable (vs. requiring `lxml`),
and should `--verbose` log progress? **ANSWER:** yes to both -- stdlib
`xml.etree.ElementTree.iterparse`, clearing the root's children after each
`<Instance>` (bounds memory regardless of file size), with `--verbose` progress
every 1,000,000 instances. A full real run is expected to take on the order of
minutes; `--dry-run` intentionally skips parsing so it stays fast.

**Q5 (minimized-report scope, added 2026-08-12):** find_collisions.minimized.csv
(§3.2) groups by the coarser `module+source` key (dropping library/configrule
from the key) and reports `library_count`/`config_rule_count`/`instance_count`.
Should it be scoped to the same colliding modules as find_collisions.csv, cover
every module+source pair in the whole design (full inventory), or apply its own
row-level filter (e.g. `library_count>1 OR config_rule_count>1`)? **ANSWER:**
scoped to the same colliding modules as §3.1 -- a module must already satisfy
§3.1's collision rule to have any rows here. Sort order matches §3.1: module
name ascending, then `instance_count` descending. Both reports are computed from
a single shared parse/`Counter` (`build_definition_counts()`), so adding this
second report does not require re-streaming the XML.

**Q6 (relative-path false positives, added 2026-08-12, later same day):** real
data showed modules (e.g. `arf044b032e1r1w0cbbehraa4acw_clk`) appearing to
collide purely because two different instantiating callers reached the same
definition file via differently-spelled `../../..` relative-path traversals
(same real file underneath). find_collisions.minimized.realpath.csv (§3.3) was
added to collapse `source` via `os.path.realpath` before re-applying the `>1`
collision rule. User-confirmed: **a module must be dropped from this report
entirely once realpath-collapsing leaves it with only one distinct module+source
entry** -- the same ">1" rule, just re-checked post-canonicalization, not a
separate/relaxed rule for this file.

**Q7 (distinct-SOURCE required for minimized reports, added 2026-08-12, later
same day, bug report):** real data showed
`arf020b064e1r1w0cbbehraa4acw_ctech_mux_2to1` as a single row in
find_collisions.minimized.realpath.csv (`library_count=2`) -- two different
library names (`IOMMU_PWTRK_ARRAY_WRAPPER_LIB`, `MSE_WRAPPER_ARRAY_WRAPPER_LIB`)
both resolved (via realpath, through a symlink) to the exact same source file.
The user considered this NOT a real "collision between multiple module
definitions" -- just one file with two library labels. **ANSWER:** for §3.2 and
§3.3 ONLY (find_collisions.csv/§3.1 keeps its original "any field differs"
rule, Q2, unchanged), a module now qualifies only if it has more than one
**distinct source**, ignoring library/configrule entirely for the
qualification check (`modules_with_multiple_sources()`, which replaced
`colliding_modules()` as §3.2/§3.3's gating filter -- `colliding_modules()` is
still used for §3.1 and remains a valid, safe performance pre-filter for §3.3's
realpath canonicalization scope, since a distinct-source module set is always a
subset of a colliding one).

**Q8 (per-configrule columns + Excel workbook, added 2026-08-13):** user wanted
a way to see, per module+source, WHICH configrule(s) produced it -- so a
reviewer can tell whether every colliding definition was found via the safer
"parent cell's library" rule (precedence-based) vs. the riskier "default
library search order" rule (search-path-order dependent), and wanted all 3
CSVs also available as one Excel workbook with real Table objects.
**ANSWER:** §3.2/§3.3 get one 1/0 column per DISTINCT configrule value found
ANYWHERE in the whole XML (`all_configrule_values()`, sorted alphabetically) --
not just values seen among the qualifying rows -- so a configrule that never
causes a collision still gets a column (all zeros). `sum(these columns) ==
config_rule_count` for every row. find_collisions.csv (§3.1) is UNCHANGED (no
new columns). Also added find_collisions.xlsx (§3.4): one workbook, 3 sheets
(`collisions`/`minimized`/`minimized_realpath`), each sheet's data wrapped in
an Excel Table object. This introduces the tool's first non-stdlib dependency:
`openpyxl` (verified installable via `pip install --user openpyxl` in this
environment; not preinstalled on the default `/usr/intel/bin/python3` or its
sibling interpreters).

---

## 7. Test plan

Table-driven, fixture-built XML (both plain and gzipped, via magic-byte
detection) -- no dependency on the real 14.6 GB file in unit tests.

1. **Unit -- gzip auto-detection (`TestOpenXml`):** plain file, `.gz` file, and a
   gzip-magic-byte file *without* a `.gz` suffix all open and read correctly.
2. **Unit -- XML streaming (`TestIterDefinitions`):** a small fixture with the
   real top-instance (`TopDetails`) + one regular instance (`InstanceDetails`)
   yields the expected `(module, library, configrule, source)` tuples in
   document order; `--verbose` emits a periodic + final progress message via an
   injectable `log` callable.
3. **Unit -- collision derivation (`TestCollectCollisionRows`):** a module with
   one definition (even with instance_count > 1) is excluded; a module bound to
   two libraries is a collision (both rows kept, sorted by descending
   instance_count); a module with same library/source but differing configrule
   is still a collision; multi-module sort order (module name, then descending
   instance_count) is exact.
4. **Unit -- minimized derivation (`TestCollectMinimizedRows`):** a module with
   one definition is excluded; a module with 2 different libraries but an
   IDENTICAL source is excluded (§6 Q7 -- library/configrule-only differences
   don't qualify here even though they do for §3.1); a module's tuples are
   correctly grouped by `module+source` with accurate `library_count`/
   `config_rule_count`/summed `instance_count` once it has ≥2 distinct sources;
   sort order (module, then descending instance_count) matches §3.1.
5. **Unit -- CSV writing (`TestWriteReport`):** header is written even for zero
   rows, for both the collisions and minimized field sets; a row round-trips
   including the `source` field's embedded comma/quotes (verifies standard `csv`
   module quoting, not manual escaping).
6. **Unit -- CLI/preflight (`TestPreflightAndCli`):** missing `--xml` fails
   preflight with exit code 2; `--dry-run` writes none of the three files; a
   real run writes find_collisions.csv, find_collisions.minimized.csv, and
   find_collisions.minimized.realpath.csv into CWD with the expected
   row counts/content; a dedicated test reproduces the reported
   `../../..`-spelling bug end-to-end and asserts the affected module appears in
   the first two reports but is completely absent from the realpath report.
7. **Unit -- realpath canonicalization (`TestCanonicalizeSource`,
   `TestBuildRealpathCounts`):** collapsing a relative traversal to its absolute
   form; two differently-spelled traversals to the same real file produce the
   same canonical source; differing line numbers stay distinct; an unparsable
   `source` string passes through unchanged; `build_realpath_counts()` merges
   instance counts for tuples that canonicalize to the same key and honors its
   `modules` filter (used to scope realpath() calls to already-colliding modules
   only).
8. **Smoke (opt-in, not part of the unit suite):** run against a real,
   well-formed slice of `config_diagnostics.xml.gz` and inspect the report by
   eye. Done once during Phase 1 against a 5 MB / 5,815-instance real-data slice
   -- 106 genuine collisions found, correctly quoted/sorted. Re-run in Phase 3:
   the minimized report (63 rows) collapsed to 54 rows in the realpath report on
   the same slice, confirming real relative-path false positives exist and are
   correctly removed.
9. **Unit -- distinct-source qualification (`TestModulesWithMultipleSources`):**
   a module with 2 libraries but 1 identical source is NOT multi-source; a
   module with 2 distinct sources IS; `modules_with_multiple_sources()` is
   always a subset of `colliding_modules()` on the same counts (the invariant
   §4 relies on to keep §3.3's realpath-scoping performance optimization valid).
10. **Unit -- per-configrule columns (`TestCollectMinimizedRows`,
    `TestAllConfigruleValues`):** `all_configrule_values()` returns every
    distinct configrule value in the whole-XML counts, including one that only
    appears on a non-colliding module; `collect_minimized_rows(counts,
    all_configrules)` sets a 1/0 value per configrule column matching row
    membership, and `sum(columns) == config_rule_count` for every row; passing
    `all_configrules=None` (the default) omits the columns entirely (back-compat).
11. **Unit -- Excel workbook (`TestWriteExcelWorkbook`):** `write_excel_workbook()`
    writes one sheet per (name, rows, fields) tuple with the header row always
    present, wraps each sheet's range in a Table object (verified via
    `openpyxl.load_workbook()` round-trip, including a zero-data-row sheet whose
    Table ref is header-only); the CLI integration test
    (`test_main_writes_report_in_cwd`) also asserts find_collisions.xlsx exists
    with the 3 expected sheet names.

<!-- Make helper subprocesses INJECTABLE (default = real runner) so tests mock them. -->

---

## 8. Implementation plan (phased)

- **Phase 0 (this spec):** ✅ **DONE** -- scope + all open questions resolved via
  §6 Q1-Q4, verified against real on-disk data.
- **Phase 1:** ✅ **DONE** (2026-08-12) -- `find_collisions.py` +
  `test_find_collisions.py`: CLI, pre-flight, streaming XML parse
  (`iter_definitions`), collision derivation (`collect_collision_rows`), CSV
  report writer, `--dry-run`/`--force`/`--verbose`. 15 unit tests pass
  (`python3 -m unittest test_find_collisions -v` from scripts/rtl/). Smoke-tested
  against a real 5 MB config_diagnostics.xml.gz slice (5,815 instances, 106
  colliding rows produced, correctly sorted/quoted).
- **Phase 2:** ✅ **DONE** (2026-08-12, same day) -- added
  find_collisions.minimized.csv (§3.2): refactored the single XML parse into a
  shared `build_definition_counts()` Counter so both reports derive from one
  pass; `colliding_modules()`, `collect_minimized_rows()`. 19 unit tests pass.
- **Phase 3:** ✅ **DONE** (2026-08-12, later same day) -- added
  find_collisions.minimized.realpath.csv (§3.3): `canonicalize_source()`
  (regex-parse + `os.path.realpath`) and `build_realpath_counts()` (re-key +
  merge, scoped to already-colliding modules for performance), reusing
  `colliding_modules()`/`collect_minimized_rows()` unchanged. 26 unit tests
  pass, including an end-to-end reproduction of the reported
  `../../..`-spelling false-positive bug.
- **Phase 4:** ✅ **DONE** (2026-08-12, later same day, bug fix) -- tightened
  §3.2/§3.3's qualification rule to require >1 DISTINCT SOURCE (§6 Q7), fixing
  a real false positive where 2 library labels on one identical source file
  (resolved through a symlink) showed as a single misleading row. New
  `modules_with_multiple_sources()` replaces `colliding_modules()` as the
  gating filter for both minimized reports; `colliding_modules()` is unchanged
  and still used for find_collisions.csv and as §3.3's realpath-scoping
  performance pre-filter. 30 unit tests pass. This was the tool's originally
  planned final phase.
- **Phase 5:** ✅ **DONE** (2026-08-13) -- added per-configrule 1/0 columns to
  §3.2/§3.3 (`all_configrule_values()`, extended `collect_minimized_rows()`;
  §6 Q8) and find_collisions.xlsx (§3.4, `write_excel_workbook()` using
  `openpyxl` Table objects, the tool's first non-stdlib dependency). 34 unit
  tests pass.

---

## 9. Non-goals

- **No full-inventory mode.** There is no flag to emit the unfiltered
  module+library+configrule+source inventory (~78K+ rows on real data) -- only
  the collisions-only report (§6 Q1) is produced.
- **No severity/classification of collisions** (e.g. distinguishing a harmless
  configrule-only difference from a real library/source conflict) -- every
  collision is reported the same way; the human reviews the CSV. (The §3.2/§3.3
  per-configrule columns, added in Phase 5, make it easier for the reviewer to
  spot which configrule(s) produced a definition, but the tool itself still
  does not compute or flag a risk score.)
- **No fix-up/auto-resolution** of collisions (e.g. suggesting which definition
  to keep) -- report-only tool, does not modify the design or its config.
- **No cross-run diffing** (comparing find_collisions.csv between two XML dumps)
  -- out of scope for this tool (would be a separate compare-style tool, as with
  `compare_pprtl2` for `report_pprtl2`).
- **No `lxml` dependency** -- stdlib `xml.etree.ElementTree` only (§6 Q4).
- **No realpath-collapsing of `library`/`configrule` fields, or of §3.1's full
  4-tuple report** -- only §3.2's minimized report gets a realpath-collapsed
  variant (§3.3); find_collisions.csv always shows raw, uncollapsed text.
- **No symlink-alias reporting** -- if realpath-collapsing merges two sources
  because one path traverses a symlink, the report only shows the final
  canonical path, not which original spellings were merged into it.


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
