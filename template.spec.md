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

Status: **DRAFT** — <phase / what's done / date>
Owner: <user>
Language: <e.g. Python 3 (driver), reusing existing helpers>
Scope: "start small" — <the narrowest useful first deliverable>

---

## 1. Purpose

<What the tool produces and for whom, in 3-5 sentences.> State the two properties
most automation should guarantee:

- **Generative & idempotent:** re-running reproduces the same output tree from the
  same inputs.
- **Non-destructive to sources:** it does not modify its inputs, and (state whether)
  it does not run the downstream flow itself.

---

## 2. Inputs (sources of truth)

List every input as a numbered source so the rest of the doc can reference `S1`, `S2`, …
Include the *exact* path shape and any auto-detection/selection rule.

| # | Source | Provides | Notes (exact paths, selection rules, gotchas) |
|---|--------|----------|-----------------------------------------------|
| S1 | <e.g. reference model symlink> | <what it provides> | <exact path shape; auto-detect rule if layout varies> |
| S2 | <config/list file> | <list of items to iterate> | <selection rule; how comments are ignored> |
| S3 | <templates dir> | <static/near-static outputs> | <curated in-repo> |
| S4 | <helper scripts/tools> | <transforms> | <invoked as subprocess> |

<!-- Tip: where a real input layout varies between targets, prefer AUTO-DETECT
     (probe the disk) over hardcoding, and record the observed variants. -->

**Line-level modifiers & precedence (if applicable).** An input list line may carry
an optional modifier (e.g. a `KEY=<value>` suffix). State how repeated modifiers
combine (union / override / last-wins). If the same logical item can be defined by
more than one source, define **precedence** explicitly (e.g. *first-listed wins*).

**Indirection / token resolution (if applicable).** If an input names its target
indirectly — via a key that dereferences to another field, a `token(...)` expression,
or a symlink — specify the resolution algorithm, whether substitution is **recursive**,
and a **fallback** for when the explicit form is absent (e.g. discover the target on
disk under a known base path, disambiguating by a stable token). Give a worked example
and record the verified real-world variants in the Decisions log (§6).

### 2.1 Profiles / variants (if the tool supports multiple targets)

If one tool serves several targets (dies, projects, configs), define a built-in
**profile map** keyed by a `--<selector>` flag, with CLI overrides for each field.

| `--<selector>` | field A | field B | example input | example output |
|----------------|---------|---------|---------------|----------------|
| <target1> | … | … | … | … |

Auto-detected vs. profile vs. CLI-override: state which fields are which.

### 2.2 Pre-flight validation (fail fast)

Before writing **anything**, validate all inputs and **fail fast** with a clear,
actionable error. List the exact checks (existence, resolves-to-dir, required
sub-paths present). Principle: *no partial output trees on bad input.*

---

## 3. Outputs (the generated tree)

Show the full output tree with a one-line comment per entry and its source.

```
<output_root>/
├── <file_a>              # from S3 template (verbatim)
├── <file_b>              # <target>-specific template
├── <dir_c>/              # verbatim directory copy
├── <tool>_report.csv     # machine-readable per-item report
├── <tool>_report.summary # human summary
├── <tool>_<items>.list   # successful items, one per line
└── <item>/
    └── <generated_file>  # produced by a helper
```

---

## 4. Per-item derivation rules

**Per-item gate:** state the inputs that must all exist for an item's outputs to be
produced. Missing → skip that item (still record it in the report).

**Post-generation disqualification (if any):** some failures are only visible after
running a helper (e.g. a helper reports N missing sub-items). Define such categories
explicitly, decide whether they still count as "ran", and keep categories
**mutually exclusive** so they reconcile: `total = ran + skipped + <fail categories>`.

**Reports** (write these every run, overwriting prior copies):

- **CSV** — `<tool>_report.csv`: one row per item, existence flags + created flags +
  any failure columns. Machine-readable (`yes`/`no`/`N/A`).
- **Summary** — `<tool>_report.summary`: a **header** (tool name + run timestamp),
  then totals + each category with count and % (1 decimal, denominator = total items),
  followed by a `[category]` section listing the member items. Align columns for
  readability. Print the **same** per-item summary lines to **STDOUT** and the report
  top from a single shared helper (avoid drift between console and file).
- **List** — `<tool>_<items>.list`: the fully-successful items only, one per line.

**Report-only anomalies (don't fail the run):** where an item references something
that cannot be resolved (e.g. a name with no matching definition), record it in the
report as a **report-only** entry rather than aborting — but scope the check tightly
(e.g. only flag names that match a known prefix) to avoid false positives.

**Per-output table:**

| Output | Source | Transform |
|--------|--------|-----------|
| `<file>` | S3 `<template>` | Copy verbatim / substitute / generate via helper |

---

## 5. CLI

```
<tool>.py \
  --<selector>  {t1|t2|...}   # selects the profile (required)
  --<in-a>      <path>        # default: <...>
  --items       <a,b,c>       # default: all from S2
  [--dry-run] [--force] [--verbose]
```

Conventions (recommended for all automation):
- `--dry-run` — print the plan (every planned path/action), write nothing.
- `--force` — overwrite existing outputs; default **skips** existing (idempotent).
- `--verbose` — log each file written.
- Validate all inputs before writing any output (fail fast).

---

## 6. Decisions log (resolved questions & notes)

Keep this section append-only. It is what lets the spec be re-ingested reliably.

**Verified on disk (<date>):** <the concrete facts you confirmed against real data>.

> **Note N1 — <short title> (flag only):** <observation / drift to confirm later>.
> ANSWER: <decision>

- **Q1** <question> — <answer>
- **Q2** <question> — <answer>

---

## 7. Test plan

Table-driven, no live tool dependency in unit tests.

1. **Unit — input parsing:** parse a fixture config; assert the selected item set
   (including edge cases: comments, variant formats).
2. **Unit — path derivation:** pure functions; assert every source/output path string.
3. **Unit — template copy:** copy into a temp tree; assert byte-identical content and
   correct naming/placement.
4. **Integration (mocked):** inject fake helper runners that write sentinel files;
   assert the full tree + reports are produced; assert `--dry-run` writes nothing and
   `--force` overwrites.
5. **Smoke (opt-in):** run one real item end-to-end; diff against a known-good tree.

<!-- Make helper subprocesses INJECTABLE (default = real runner) so tests mock them. -->

---

## 8. Implementation plan (phased)

- **Phase 0 (this spec):** approve scope + resolve open questions.
- **Phase 1:** skeleton — CLI, pre-flight validation, input parsing, `--dry-run` plan.
  Unit tests 1–2.
- **Phase 2:** static outputs (verbatim copies, per-item static files). Unit test 3.
- **Phase 3:** generated outputs (wire helper subprocesses) + reports. Integration test 4.
- **Phase 4:** full-scale smoke run; document usage.

Update each bullet with ✅ **DONE** + a one-line result as phases land.

---

## 9. Non-goals (for now)

- <explicitly out of scope>

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
