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

Status: **Phase 2 delivered** (XML-derived collision reports, module expanded
reporting, and the opt-in `--paranoia` cross-file consistency check of §1's first
bullet -- see §6 Q9/Q11 and §8)
Owner: mroha
Language: Python 3 (stdlib, plus `openpyxl` for the .xlsx workbook -- see §3.4).  Runs in a Python UV workspace, so use UV to install new packages if needed.  Use pytest for test infrastructure.
Scope: Using the VCS elaboration XML dump, detect potentially problematic cases where RTL has multiple different definitions
Implementation: scripts/rtl/find_collisions

---

## 1. Purpose

This tool has two purposes:
  - Identify any inconsistencies between the key files used for generation of RTL to SD handoff: config_diagnostics.xml, fullchipdump, rtl 2stage, and generated verilog configuration _cfg.sv (opt-in, `--paranoia`, §3.5)
  - Build human readable and XLS reports showing the bindings of RTL modules to libraries and config rules, and highlight any modules that have multiple definitions (collisions).

- **Generative & idempotent:** re-running reproduces the same output tree from the
  same inputs.
- **Non-destructive to sources:** it does not modify its inputs.

---

## 2. Inputs (sources of truth)

List every input as a numbered source so the rest of the doc can reference `S1`, `S2`, …
Include the *exact* path shape and any auto-detection/selection rule.

--fe_collateral <path to the top level fe_collateral directory> (e.g., `/nfs/site/disks/corhub_fe_mod_0000/corhub_oks/corhub_oks-a0-corhub_oks-26ww34f/output/imh/partition/corimh/h2b/trial/fe_collateral`)

For a directory with format:  /nfs/site/disks/corhub_fe_mod_0000/corhub_oks/corhub_oks-a0-corhub_oks-26ww34f/output/imh/partition/corimh/h2b/trial/fe_collateral

The parameters are like so:  <REF_MODEL>/output/<DUT>/partition/<BLOCK>/h2b/trial/fe_collateral

BLOCK and RTL TOP_MODULE_NAME are synonymous.



| # | Source | Provides | Notes (exact paths, selection rules, gotchas) |
|---|--------|----------|-----------------------------------------------|
| S1 | <BLOCK>_cfg.sv | Generated verilog configuration that provides what instances are bound to which model definitions+libraries | Located in fe_collateral directory. Only read with `--paranoia` (~3.9 GB on real data, streamed line by line) |
| S2 | rtl_list_2stage.tcl | Ordered handoff filelist which contains which contains what design files and search paths are loaded for each library | Located in fe_collateral directory. Existence-checked and reported; not yet parsed |
| S3 | fullchipdump.final.py.sort(.zst) | Intermediate file used to generate <BLOCK>_cfg.sv. Generated from config_diagnostics.xml | Location of fullchipdump found by reading fe_collateral/../log/<BLOCK>.v2k_config.syn.log. Path will be located near the top of the log file.  File may be zstd compressed (.zst). Only read with `--paranoia` |
| S4 | config_diagnostics.xml(.gz) | VCS elaboration dump  | Contains a map of instance-definition relationships for the RTL design hierarchy.  This file can be quite large. | Location of XML found by from location of fullchipdump.  Up one directory from location of fullchipdump into flow_inputs.  fullchipdump.config.log contains a key-value pair VCS_CONFIG_XML.   Note the xml file may be gzipped (.gz) |

Some of these files can be quite large, so optimize for runtime where possible.


<!-- Tip: where a real input layout varies between targets, prefer AUTO-DETECT
     (probe the disk) over hardcoding, and record the observed variants. -->


---

### 2.1 Pre-flight validation (fail fast)

**Checks:**
- Existence of input directory and files (S1-S4)

---

## 3. Outputs (the generated tree)

Output root is CWD

```
<output_root>/
└── find_collisions.xlsx                      # Excel workbook with 2 sheets: §3.2 and §3.3
└── find_collisions.module.xlsx               # Only with --modulefile/--module; 4 sheets (§3.4)
└── find_collisions.report                    # Human readable report of the run (§3.1)
```


## 3.1 find_collisions.report
Contains human readable summary of run, and is also echoed to stdout.
- Command line
- Reference model (REF_MODEL)
- DUT
- Block (BLOCK)
- _cfg.sv path
- rtl_list_2stage.tcl path
- fullchipdump.final.py.sort(.zst) path
- config_diagnostics.xml(.gz) path
- modulefile path (only when `--modulefile` was given)
- Number of data rows written to each sheet of each output workbook
- `patterns:` -- the module patterns that were provided, one per line, in the
  order given (`--modulefile` contents, or the single `--module` name). Omitted
  when neither flag was used.
- `paranoia results:` -- only when `--paranoia` was given (§3.5)
- Any notes (currently only the Excel row-limit truncation warning, §3.4)


## 3.2 find_collisions.xlsx "raw" sheet
**Description:** This sheet contains a machine-readable report of the RTL modules that
potentially **collide** — i.e. the same module name is bound to more than one distinct
(library+surce) combination somewhere in the design. Modules with
exactly one definition are **not** included; only the colliding module's rows (all of its distinct
definitions) are written. See §4 for the exact collision rule and §6 Q1/Q2.

**Columns:**

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
## 3.3 find_collisions.xlsx "reduced" sheet
**Description:** A per-`module+source` rollup, but with a **stricter** qualification
rule than the raw (§3.2): a module only appears here if it has more
than one **distinct source** (a genuinely different underlying file/line) --
not merely a different library and string name.  For example,  the source file might have different link paths to the same underlying file, or a symlink might be used to reach the same file from two different library directories. So use `os.path.realpath` to resolve the `source` path. This report is intended to help a reviewer quickly see which modules have multiple definitions that are genuinely different, rather than just being labeled differently in the design hierarchy.
For each unique source file and line number,  we want to see how many different libraries and config rules are bound to that module+source pair, and how many instances of that module+source exist in the design.  The per-configrule columns (§6 Q8) allow a reviewer to see which config rules were applied to each module+source pair.

`arf044b032e1r1w0cbbehraa4acw_clk`, which appeared to collide only because its
two instantiating callers used different relative-path spellings that both
resolve to the identical absolute file:line.

**Columns:**

```csv fields
module                 # Name of the RTL module
source                  # Full source file for the RTL module and linenumber (same text as §3.2's source column)
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

## 3.4 find_collisions.module.xlsx (module expanded reporting)
**Description:** a second workbook, written ONLY when `--modulefile <file>` or
`--module <module>` is given, that zooms in on a caller-chosen subset of modules
for debugging. `--module <name>` is exactly equivalent to a modulefile holding
that single bare (exact-match) token. Unlike
§3.2/§3.3 it is NOT filtered to collisions at the module-selection level -- every
module matching a pattern is in scope (though its `raw`/`reduced` sheets still
apply their own collision rules, so a matched module with a single definition
contributes only `instances` rows). Neither flag changes find_collisions.xlsx,
which always covers the whole design.

**modulefile format:**
- One or more patterns per line, whitespace separated.
- `<string>` -- exact match against the `module` field (`xor_gate` does NOT match
  `my_xor_gate`).
- `r"<regex>"` -- Python regex applied to the whole module name with `re.search`,
  so `r"xor"` matches every module containing `xor` anywhere. The quoted form may
  contain spaces.
- Blank/whitespace-only lines and lines whose first non-space character is `#`
  are ignored.
- An unreadable file, an empty pattern set, or an uncompilable regex is a
  pre-flight failure (exit 2) -- nothing is written.

**Sheets:**

| Sheet | Columns | Content |
|-------|---------|---------|
| `patterns` | `pattern`, `kind` (`exact`/`regex`), `matched_modules` | the raw pattern list as read from the modulefile, in file order, each with the number of DISTINCT module names it matched (0 flags a dead pattern) |
| `raw` | same as §3.2 | §3.2's rows restricted to matching modules |
| `reduced` | same as §3.3 | §3.3's rows restricted to matching modules |
| `instances` | `module`, `library`, `configrule`, `source`, `instance`, `instance_source` | one row per `<Instance>` of a matching module |

`instance` is `<Hierarchy >` and `instance_source` is `<SourceInfo >` from the
instance's `<InstanceDetails >` block (`<TopDetails >` for the design top) -- NOT
the `<SourceInfo >` under `<DefinitionDetails >`, which is the existing `source`
column. Row order: module ascending, then instance path ascending.

The per-configrule 1/0 columns on `reduced` use the same whole-dump column set as
§3.3, so the two workbooks' `reduced` sheets are column-compatible.

If the `instances` sheet would exceed Excel's 1,048,576-row limit it is truncated
to fit and the number of dropped rows is recorded in the §3.1 report's notes
section (a broad regex such as `r"."` matches all 24M+ instances).

---

## 3.5 `paranoia results:` (the --paranoia cross-file check)
**Description:** an opt-in section of §3.1's report (never a separate file, never
a non-zero exit) holding two independent consistency checks. Both are computed
during the SAME single streaming pass over S4 that produces §3.2/§3.3.

**Check 1 -- S4 (XML) vs S3 (fullchipdump) are equivalent.** The fullchipdump is
generated from the XML, so every XML instance should appear in it with an
identical binding, and vice versa. The compared record is the 6-tuple
`(instance, library, module, module_file, config_rule, parent_file)` -- see §4
for the field mapping and the normalizations that make the two spellings
comparable.

**Check 2 -- every S1 (`<BLOCK>_cfg.sv`) instance binding matches S4.** Direction
is one-way, S1 -> S4: an `instance <hier> liblist <lib>;` line is a mismatch
unless the XML bound that exact hierarchy to that library (case-insensitive).
XML instances with no `_cfg.sv` line are NOT mismatches -- `_cfg.sv` legitimately
carries far fewer instances than the elaboration (16.3M vs 24.7M on real data).

**Reported lines:**

```
paranoia results:
  xml instance count:          <n>
  fullchipdump instance count: <n>
  differences found: none                    # or, when non-zero:
  differences found: <xml_only + dump_only>
    xml instances missing from the fullchipdump: <n>
      <full record>                          # up to 10, in XML document order
    fullchipdump instances missing from the xml: <n>
      <full record>                          # up to 10, in fullchipdump order
  duplicate xml records: <n> (...)           # only when non-zero
      <full record>                          # up to 10

  v2k config (<BLOCK>_cfg.sv) compare
    instances in <BLOCK>_cfg.sv: <n>
    v2k config binding mismatch from xml: <n>
      <full record>                          # up to 10, in _cfg.sv order
```

Every example is a FULL record, printed in its own file's syntax: the
fullchipdump's `{ 'instance' : r"...", 'library' : '...', ... }` dict literal for
the first three buckets (the XML-side records are re-spelled into that same
syntax, post-normalization, so the two are directly comparable and greppable),
and the raw `instance <hier> liblist <lib>;` line for the `_cfg.sv` bucket.

**Duplicate XML records.** A reference record already matched by an earlier XML
instance is counted as a duplicate, not matched twice -- otherwise `dump_only`
and the binding mismatch count would go negative (they did on real data, \u00a76 Q11).
Naming the `fullchipdump`/`_cfg.sv` buckets needs a second read of those files,
so each is re-read only when its count is non-zero, and the scan stops as soon
as 10 examples are found.

---


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
- Only colliding modules' rows are written to the `raw` sheet; every distinct
  combination for that module is written (not just the majority/minority one).
- **Row order:** module name ascending, then `instance_count` descending within a
  module (puts each collision's most-common definition first).
- The design's single top-level instance (XML `<TopDetails>` instead of
  `<InstanceDetails>`) is treated identically to every other instance — it
  contributes a tuple the same way and can, in principle, participate in a
  collision (real designs won't collide on the top module, but no special-casing
  is applied).
- **`reduced` sheet qualification (§3.3):** a module qualifies only if it has
  more than one **distinct source** (see §6 Q7) -- a library/configrule-only
  difference on an identical source does NOT qualify here, even though it does
  for §3.2's `colliding_modules()` rule. For each qualifying module, group its
  (library, configrule, source) tuples by `source`; `library_count`/
  `config_rule_count` are the counts of DISTINCT libraries/configrules seen for
  that `module+source` pair, and `instance_count` is the sum of `instance_count`
  across every (library, configrule) combo sharing that `module+source`. Row
  order: module name ascending, then `instance_count` descending within a
  module.
- **`reduced` sheet realpath derivation (§3.3):** re-key the ORIGINAL
  4-tuple counts by replacing `source`'s path with `os.path.realpath(path)`
  (keeping the line number), summing instance counts of tuples that collapse to
  the same (module, library, configrule, canonical_source) key; only tuples
  belonging to a module already in §3.2's colliding set need re-keying
  (canonicalizing can only MERGE distinct combinations, never split them, so a
  module that wasn't colliding before cannot become colliding after -- this
  keeps the number of `realpath()` filesystem calls bounded to already-flagged
  modules, not every one of the ~78K+ real combos -- and remains a valid
  performance pre-filter even though §3.2/§3.3's own qualification rule is the
  stricter distinct-source one, since a distinct-source module is always a
  subset "of a colliding one). The §3.3 distinct-source rule is then re-applied
  to this re-keyed data (via the same `modules_with_multiple_sources()`/
  `collect_reduced_rows()` helpers) -- a module drops out entirely if it no
  longer has more than one distinct canonical source.
- Both sheets are derived from a **single** pass over the XML (one
  shared in-memory `Counter` of 4-tuple instance counts) -- the file is never
  streamed twice in one run.
- **Per-configrule columns (§3.3, §6 Q8):** the set of extra columns is
  every DISTINCT configrule value found anywhere in the raw (whole-XML,
  pre-filter) counts -- `all_configrule_values()`, sorted alphabetically for a
  stable column order -- NOT just the configrule values that happen to appear
  among the qualifying/colliding rows. Both workbooks' `reduced` sheets use this
  SAME column set (computed once, from the original counts). For each row, a
  column's
  value is 1 if that configrule was one of the DISTINCT configrules bound to
  that row's `module+source` pair (the same set backing `config_rule_count`),
  else 0 -- so `sum(these columns) == config_rule_count` always holds.
- **Workbook derivation:** one sheet per table above, each sheet's full
  header+data range wrapped in an Excel Table object. Built from the exact same
  in-memory rows/fieldname lists used for the row counts in §3.1 (no separate
  derivation/second pass).
- **`--paranoia` record mapping and normalization (§3.5):** an S3 fullchipdump
  line is a Python dict literal,
  `{ 'instance' : r"<hier>", 'library' : '<LIB>', 'module' : '<mod>', 'module_file' : '<path>', 'config_rule' : '<rule>', 'parent_file' : '<path>' }`.
  It maps onto the XML as `instance` = `InstanceDetails/Hierarchy` (or
  `TopDetails/Hierarchy`), `library`/`module`/`module_file` =
  `DefinitionDetails/Library`/`Module`/`SourceInfo`, `config_rule` =
  `ConfigRule/Rule`, `parent_file` = `InstanceDetails/SourceInfo`. Three
  normalizations are applied before comparing:
  1. `SourceInfo`'s `"<path>",<line>` is reduced to `<path>` -- the fullchipdump
     carries no line numbers.
  2. The XML's `parent cell's library` is spelled `parent cell_s library` in the
     fullchipdump, so `'` -> `_` on the XML side.
  3. Library names are compared case-insensitively (`_cfg.sv` writes `sca_lib`
     where the XML writes `SCA_LIB`).
  Hierarchy strings are compared BYTE-EXACT and are never stripped: an escaped
  Verilog identifier is terminated by a space, so `corimh.a.\lcb_x[0] ` and
  `corimh.a.\lcb_x[0]` are different instances (~105K such lines per 3M in real
  `_cfg.sv` data).
- **`_cfg.sv` line parsing:** anchor on the TAIL, `^instance (.*) liblist ([^ ;]+) *;`.
  A naive whitespace split misparses every escaped-identifier line (2.48M of
  16.33M on real data), because the hierarchy itself contains spaces. Lines that
  do not match (`config`/`design`/`default liblist`/`endconfig`/blank) are
  skipped.
- **`--paranoia` comparison strategy:** S3 (23.8M records) and S1 (16.3M
  bindings) are each reduced to a SORTED ARRAY of 64-bit `hash()` values
  (`array('q')` + `bisect`, ~8 bytes/record vs ~80 for a `set` of ints) that the
  single XML pass probes once per instance. Each index carries a parallel
  `bytearray` of "already matched" flags, so `dump_only` /
  `v2k config binding mismatch` are `total - distinct_matched` and an XML record
  landing on an already-matched slot is counted as a DUPLICATE instead. Naming
  the reference-side buckets is a second, early-terminating pass over the file
  concerned, taken only when its count is non-zero.

---

## 5. CLI

```
find_collisions \
  --fe_collateral <fe_collateral directory>
  [--modulefile <file> | --module <module>]   # patterns selecting modules for find_collisions.module.xlsx (§3.4); --module takes a single module name (exact match). If neither is given, the module workbook is not written.
  [--paranoia]                 # runs consistency check between xml/fullchipdump/_cfg.sv, prints any anomalies to stdout, but does not fail the run
  [--dry-run]                  # resolve and validate inputs, print plan, exit without parsing XML
  [--force]                    # always regenerate outputs (no-op here; outputs are always regenerated)
  [--verbose]                  # log progress every 1M instances, plus final counts and report paths
```

Conventions (recommended for all automation):
- `--modulefile` and `--module` are mutually exclusive (argparse rejects both).
- `--paranoia` is REPORT-ONLY: any inconsistency it finds is written to §3.5 and
  the exit code stays 0. It roughly triples the runtime (it must also stream the
  82 MB zstd fullchipdump and the 3.9 GB `_cfg.sv`, and it forces per-instance
  hierarchy extraction for all 24.7M instances), so it is opt-in.
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

**Q9 (rebuild as a uv project, added 2026-08-21):** the tool was re-scoped around
the `fe_collateral` directory as its single input and rebuilt as a uv/pytest
project. Five section conflicts were resolved with the user:
1. **§1's cross-file consistency purpose is Phase 2.** Phase 1 discovers and
   validates all four sources (S1-S4) and lists them in the report, but only the
   XML (S4) is parsed; no comparison rules between S1/S2/S3/S4 are implemented
   yet.
2. **`--fe_collateral <dir>` is the single required argument** (§5's old `--xml`
   spelling is dead); S1-S4 are auto-discovered from it, no per-file overrides.
3. **Outputs are exactly two files:** `find_collisions.xlsx` and
   `find_collisions.report`. The three standalone CSVs described in §4/§6-§8 are
   gone; their content now lives in the workbook's two sheets.
4. **Sheet `raw`** = old §3.1's collisions rule (any of library/configrule/source
   differs). **Sheet `reduced`** = old §3.3, i.e. realpath-collapsed sources with
   the ">1 distinct canonical source" qualification (Q6/Q7); the intermediate
   non-realpath minimized report (old §3.2) is no longer emitted.
5. **The text report is named `find_collisions.report`** (not `.summary`).

**Verified on disk (2026-08-21)** against
`/nfs/site/disks/corhub_fe_mod_0000/corhub_oks/corhub_oks-a0-corhub_oks-26ww34f/output/imh/partition/corimh/h2b/trial/fe_collateral`:
- S1 `corimh_cfg.sv` is 3.88 GB; S2 `rtl_list_2stage.tcl` is 12 MB. Both sit
  directly in `fe_collateral/`.
- S3 is named in exactly one line of `../log/<BLOCK>.v2k_config.syn.log`
  (`[INFO ] <path> exists! Not re-creating...`), and lives in a DIFFERENT
  workarea disk than the fe_collateral one — so it must be scraped, never derived
  by path arithmetic from `--fe_collateral`.
- S4 comes from `<fullchipdump dir>/../flow_inputs/fullchipdump.config.log`, a
  fixed-width table whose rows are `| KEY <pad> | VALUE <pad> | Default/User-cfg |`;
  the `VCS_CONFIG_XML` row holds the `.xml.gz` path.
- The XML's root element is `<InstanceList >` (not a `<ConfigDiagnostics>`
  wrapper), and both `TopDetails`/`InstanceDetails` carry their OWN `<SourceInfo >`
  — the `source` column must therefore be read from `DefinitionDetails/SourceInfo`
  specifically, not by a bare `.//SourceInfo` search.
- Smoke test on a well-formed 200,000-instance slice of the real dump: 1,910
  distinct 4-tuples, 51 colliding modules, 37 multi-source modules, 174 `raw`
  rows, 44 `reduced` rows, 3 configrule values (`Top Module`,
  `default library search order`, `parent cell's library`).

**Q10 (module expanded reporting, added 2026-08-21):** added `--modulefile` and
the second workbook §3.4 for drilling into specific modules. Design points:
- **Matching semantics:** bare token = exact equality on `module`; `r"..."` =
  `re.search` over the whole module name (substring-style, NOT anchored). Both
  forms may appear multiple times on one line.
- **Instance-level data requires a parse-time decision.** The `instances` sheet
  needs `<Hierarchy >`/`<SourceInfo >` from `<InstanceDetails >`, which the
  §3.2/§3.3 pipeline discards (it only keeps a `Counter` of 4-tuples). Rather
  than re-stream the 14.6 GB dump, `scan_dump()` now takes a `want_details`
  predicate and captures the instance block only for matching modules, in the
  SAME single pass. The predicate is a memoized `Matcher` -- with 24.7M instances
  over ~74K distinct module names, running the regexes per instance instead of
  per distinct name would dominate runtime.
- **`raw`/`reduced` are filtered, not re-derived.** Because both rules are
  strictly per-module, filtering the counts to matched modules first is
  equivalent to deriving then filtering; `filter_counts()` is shared with the
  existing `--module` flag.
- **Configrule columns stay whole-dump-wide** so the two workbooks' `reduced`
  sheets line up column-for-column.
- **`patterns` sheet carries a `matched_modules` count** so a typo'd or dead
  pattern is obvious (0) without diffing sheets.
- **Excel row limit** is enforced on `instances` with a note in the report; a
  broad regex can legitimately select more than 1,048,576 instances.

**Q11 (`--paranoia` + report format, added 2026-08-21):** the §1 cross-file check
was scoped to exactly two questions: (1) are the XML and the fullchipdump
equivalent, and (2) does every instance in `_cfg.sv` have a library binding that
matches the config diagnostics. `--module` was also re-pointed at the module
workbook (it no longer filters find_collisions.xlsx), and the report lost its
`S1`/`S2`/`S3`/`S4` line prefixes and gained `patterns:` + `paranoia results:`
sections.

**Verified on disk (2026-08-21)** against the same corimh workarea:
- Record counts differ substantially between the three files -- S4 24,701,302
  instances, S3 23,759,582 lines, S1 16,334,988 `instance ... liblist ...;`
  lines. The tool therefore reports counts per source and only ever names
  XML-side differences; `_cfg.sv` is compared one-way (§3.5) so its smaller
  population is not reported as 8M missing instances.
- S3's `config_rule` renders `parent cell's library` as `parent cell_s library`,
  and its `module_file`/`parent_file` are bare paths (no `,<line>` suffix).
- 2,481,524 of S1's 16,334,988 instance lines (~15%) are NOT parseable by a
  whitespace split: escaped Verilog identifiers such as
  `...\lcb_ClkAddrEntryWrEn4UH[g_bank][g_entry] .i_ctech_lib_clk_and_en` embed
  the terminating space in the hierarchy. Both S1 and S4 preserve that space
  (`<Hierarchy >...[g_entry] </Hierarchy >`, `instance ...[g_entry]  liblist ...;`
  with two spaces), so `_text()` in `xmlstream.py` must NOT `.strip()` -- that
  was a real bug found by this exercise.
- S1 writes library names in lower case (`liblist sca_lib;`) where S4 writes
  `SCA_LIB`, hence the case-insensitive library comparison.
- Memory: holding 24M parsed records (or even a `set` of their hashes, ~1.8 GB
  each) is not acceptable alongside the existing pass, so both reference files
  become sorted `array('q')` hash indexes (~190 MB each) probed with `bisect`.
- S3 is zstd-compressed, adding `zstandard` (0.25.0) as the tool's second
  non-stdlib dependency; `open_text()` dispatches on magic bytes (zstd, gzip,
  plain) exactly like `open_xml()`.
- **The XML repeats instances; the fullchipdump does not.** The first real
  `--paranoia` run returned NEGATIVE differences, because more XML records
  matched a dump record than there were dump records. Verified independently:
  the fullchipdump's 23,759,582 instance paths are all distinct (`uniq -d`
  returns nothing) and every XML record was found in it, so 941,720 of S4's
  24,701,302 records repeat an instance+binding already emitted. Matches are
  therefore counted per DISTINCT reference record (a `bytearray` of flags
  alongside each hash index) and the repeats are reported as
  `duplicate xml records`.
- **Real corimh result** (11m20s, ~1.2 GB peak): XML vs fullchipdump
  `differences found: none`, 941,720 duplicate XML records (all observed
  examples are ctech clock/reset buffer instances, e.g.
  `...cbaddrm.lcb_ClkRstFree4UH.i_ctech_lib_clk_and_en`), and 0 of 16,334,988
  `_cfg.sv` bindings disagree with the elaboration. So the handoff files ARE
  consistent on this model; the only anomaly is the XML's repeated instances.

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
12. **Unit -- paranoia (`tests/test_paranoia.py`):** `open_text()` reads plain,
    gzip and zstd bytes; `DUMP_RE` parses a real-shaped fullchipdump line whose
    hierarchy contains an escaped identifier (embedded space); `CFG_RE` keeps the
    TRAILING space of an escaped identifier and rejects the `config`/`design`/
    `default liblist`/`endconfig` lines; `HashIndex` membership; and, driven
    through `scan_dump(..., observe=...)` over fixture XML: consistent inputs
    report zero differences, an instance missing from the dump is counted and
    NAMED as a full record, a re-bound instance produces a full record in BOTH
    the xml-missing and dump-missing buckets, an extra dump record appears in the
    dump-missing bucket, a repeated XML instance is counted as a duplicate (not
    twice) and named, a `_cfg.sv` library change is counted and its raw line
    named while a case-only change is not, the example lists are capped at
    `EXAMPLE_LIMIT`, and `observe` does not retain any records in
    `Scan.instances`. The CLI test `test_paranoia_reports_and_never_fails`
    asserts the §3.5 lines land in the report with exit code 0.

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
- **Phase 1 (rebuild):** ✅ **DONE** (2026-08-21) -- rebuilt as a uv workspace
  project (`src/find_collisions/`, pytest under `tests/`, console script
  `find-collisions`) around the resolved §6 Q9 decisions:
  - `paths.py` -- `parse_fe_collateral()`, `find_fullchipdump()`,
    `find_config_xml()`, `resolve_inputs()` (fail-fast preflight over S1-S4).
  - `xmlstream.py` -- `open_xml()` (gzip magic-byte detection),
    `iter_definitions()` (`iterparse` + root-clearing), `build_definition_counts()`.
  - `collisions.py` -- `colliding_modules()`, `modules_with_multiple_sources()`,
    `all_configrule_values()`, `canonicalize_source()`, `build_realpath_counts()`,
    `collect_raw_rows()`, `collect_reduced_rows()`.
  - `report.py` -- `write_excel_workbook()` (one Table per sheet),
    `summary_lines()`/`write_summary()`.
  - `cli.py` -- `--fe_collateral`, `--module`, `--dry-run`, `--force`, `--verbose`;
    exit code 2 on preflight failure.
  36 pytest tests pass (`uv run pytest`); `--dry-run` verified end-to-end against
  the real corimh workarea, and the derivations against a 200K-instance real slice.
- **Phase 1b (module expanded reporting):** ✅ **DONE** (2026-08-21) -- `--modulefile`
  + find_collisions.module.xlsx (§3.4, §6 Q10). New `patterns.py`
  (`parse_patterns()`/`load_patterns()`/`Matcher`/`pattern_rows()`);
  `xmlstream.iter_definitions()`/`build_definition_counts()` became
  `iter_records()`/`scan_dump()` returning a `Scan(counts, instances)` with an
  optional `want_details` predicate; `collisions.filter_counts()` and
  `collect_instance_rows()`. 53 pytest tests pass.
- **Phase 2 (paranoia):** ✅ **DONE** (2026-08-21) -- the §1 cross-file consistency
  check, opt-in behind `--paranoia` (§3.5, §6 Q11). New `paranoia.py`
  (`open_text()` zstd/gzip/plain reader, `DUMP_RE`/`CFG_RE` parsers, `HashIndex`,
  `ParanoiaChecker`, `build_checker()`, `paranoia_lines()`);
  `xmlstream.scan_dump()` gained an `observe` hook (and `_text()` stopped
  stripping, which was corrupting escaped-identifier hierarchies);
  `report.summary_lines()` gained `patterns`/`paranoia` sections and dropped the
  `S1..S4` prefixes; `--module` now selects the module workbook instead of
  filtering the main one. S2 (`rtl_list_2stage.tcl`) is still only
  existence-checked -- no rule involving it has been specified.

---

## 9. Non-goals

- **No full-inventory mode.** There is no flag to emit the unfiltered
  module+library+configrule+source inventory (~78K+ rows on real data) -- only
  the collisions-only report (§6 Q1) is produced.
- **No severity/classification of collisions** (e.g. distinguishing a harmless
  configrule-only difference from a real library/source conflict) -- every
  collision is reported the same way; the human reviews the workbook. (The §3.3
  per-configrule columns make it easier for the reviewer to
  spot which configrule(s) produced a definition, but the tool itself still
  does not compute or flag a risk score.)
- **No fix-up/auto-resolution** of collisions (e.g. suggesting which definition
  to keep) -- report-only tool, does not modify the design or its config.
- **No cross-run diffing** (comparing find_collisions.xlsx between two XML dumps)
  -- out of scope for this tool (would be a separate compare-style tool, as with
  `compare_pprtl2` for `report_pprtl2`).
- **No `lxml` dependency** -- stdlib `xml.etree.ElementTree` only (§6 Q4).
- **No realpath-collapsing of `library`/`configrule` fields, or of the `raw`
  sheet** -- only the `reduced` sheet (§3.3) is realpath-collapsed; `raw`
  always shows the uncollapsed text.
- **No symlink-alias reporting** -- if realpath-collapsing merges two sources
  because one path traverses a symlink, the report only shows the final
  canonical path, not which original spellings were merged into it.
- **`--paranoia` never fails the run** and never writes its own file -- it is a
  report-only section of §3.1 (exit code stays 0 no matter how many differences
  are found).
- **`--paranoia` names at most 10 records per bucket**, not the full difference
  list -- it is a triage aid, not a diff tool.
- **No S2 (`rtl_list_2stage.tcl`) checks** -- the filelist is discovered,
  validated and reported, but no rule comparing it to S1/S3/S4 is specified.


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
