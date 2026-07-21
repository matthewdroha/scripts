# Spec: `prep_pprtl2` — pprtl2 run-area preparation workflow

Status: **PHASE 3 COMPLETE** — full workflow implemented + validated live on imh (2026-07-14). Generated collateral (`hip.ldb.list.minimized`, `<partition>_clocks.tcl.fixclocks`, `elab.pre.tcl`) via the perl helpers + report CSV/summary. Multi-die, SDC_ARCHIVE, auto h2b sublevel, per-die blocks.cfg, hier_type/par-fallback partition selection all resolved.
Owner: mroha
Language: **Python 3** (driver), reusing existing Perl helpers
Scope: "start small" — generate the output tree deterministically from known sources for a given DUT (`imh`, `ioh`, or `cbb0`) across its partitions.

> Reusable structure/patterns from this spec are distilled in [../spec_template.md](../spec_template.md) for future automation projects.

---

## 1. Purpose

`prep_pprtl2` assembles a ready-to-run **pprtl2** (RTL power analysis) work area under
`$WORKAREA/power/pprtl2/`. It collects collateral from several sources (a GK reference
model, stdcell libraries, Cheetah-RTL, and partition/blocks config) and emits a set of
directories and text files that the Cheetah-RTL `pprtl2` flow consumes.

The workflow is **generative and idempotent**: re-running it reproduces the same output
tree from the same inputs. It does **not** run the pprtl2 flow itself, nor does it modify any source files.

---

## 2. Inputs (sources of truth)

| # | Source | Provides | Notes |
|---|--------|----------|-------|
| S1 | **GK reference model** — symlinked as `$WORKAREA/power/pprtl2/REF_MODEL` (e.g. `/nfs/site/disks/corhub_fe_mod_0000/corhub_oks/corhub_oks-a0-corhub_oks-26ww27e`) | Per-partition 2-stage filelist + hip ldb list | Per-partition base: `output/${DUT}/partition/<partition>/h2b/<sub>/` where `<sub>` is **auto-detected**: prefer `h2b/trial/`, else the sole subdir under `h2b/` (verified: imh/ioh=`trial`, cbb0=`cbb0`); ambiguous/absent ⇒ partition skipped. 2stage: `.../h2b/<sub>/fe_collateral/rtl_list_2stage.tcl`; hip: `.../h2b/<sub>/hip_collaterals/hip.ldb.list` |
| S2 | **Partition/blocks config** — `$WORKAREA/partition/<blocks.cfg>` (imh/ioh: `<DUT>.blocks.cfg`; cbb0: `cbb0_h2b.blocks.cfg`; override via `--blocks-cfg`) | List of `<partition>` names | **Selection:** if the file has any `hier_type` field, take `hier_type = part` (imh); otherwise fall back to `block_type = partition` **and** name starts with `par` (ioh/cbb0). Comment lines and commented-out headers (`#[...]`) are ignored. Verified counts: imh 187, ioh 146, cbb0 47. |
| S3 | **stdcell libraries** — `/p/hdk/cad/stdcells/...` | `stdcell.ldb.list` contents | See open question Q1 (static template vs. generated) |
| S4 | **Cheetah-RTL** — `cth_query -tool cheetah-rtl` → `$CHEETAH_RTL_ROOT` | `Makefile` include target (`lowpower/pprtl2/Makefile.pprtl2`) | Referenced at make-time, not copied |
| S5 | **Templates** — `scripts/pprtl2/cor/` (`Makefile`, `partition.flow.cfg`, `tool.cth`, `activity_dir.map`, `grdlbuild/`, per-die `<DUT>/stdcell.ldb.list`) | Static/near-static output templates | Curated in-repo |
| S6 | **Perl helpers** — `scripts/pprtl2/minimizehip.pl`, `scripts/pprtl2/fixclocks.pl` | Transform S1 collateral into minimized/fixed outputs | Called as subprocesses |
| S7 | **Clock SDC** — symlinked as `$WORKAREA/power/pprtl2/SDC_ARCHIVE` (e.g. `/nfs/site/disks/corimh.arc.proj_archive/arc`) | Per-partition clock collateral release dir | Release dir = `$SDC_ARCHIVE/<partition>/clock_collateral/<sdc release>/`. **Selection rule:** per die profile (§2.1) — keep dirs whose name (case-insensitive) starts with the die prefix **and** contains the die's required token, then pick the **newest by directory mtime**. Quick-reject the partition if `<release>/<partition>_clocks.tcl` is missing before running fixclocks. Partition dir names match S2 blocks.cfg names (verified). |
---

## 2.1 Die profiles (multi-die support)

`prep_pprtl2` supports three Coral dies, selected via `--dut`. A built-in profile map supplies the die-specific clock-release filter; `--clock-release-prefix` / `--clock-release-token` override the defaults.

| `--dut` | Clock prefix | Token | blocks.cfg | h2b sublevel | Example REF_MODEL | Example SDC area |
|---------|--------------|-------|------------|--------------|-------------------|------------------|
| `imh`  | `CORIMH`  | `H2B`     | `imh.blocks.cfg`      | `trial` | `.../corhub_oks-a0-corhub_oks-26ww27e` | `/nfs/site/disks/corimh.arc.proj_archive/arc` |
| `ioh`  | `CORIOH`  | `H2B`     | `ioh.blocks.cfg`      | `trial` | `.../dmrhub2-a0-corioh-26ww27a`        | `/nfs/site/disks/dmr2_arc_proj_archive/arc` |
| `cbb0` | `CORCBBP` | `CONTOUR` | `cbb0_h2b.blocks.cfg` | `cbb0`  | `.../corcbbp-a0-corcbbp-26ww27c`       | `/nfs/site/disks/corcbbp.arc.proj_archive/arc` |

The `blocks.cfg` name and clock filter are built-in per die (overridable via `--blocks-cfg`, `--clock-release-prefix`, `--clock-release-token`). The **h2b sublevel is auto-detected**, not hardcoded: prefer `h2b/trial/`, else the sole subdir under `h2b/`; if `h2b/` is missing or has multiple non-`trial` subdirs the partition is skipped (missing 2stage/hip).

**Clock-release selection (per partition):** among dirs under `$SDC_ARCHIVE/<partition>/clock_collateral/`, keep those whose name (case-insensitive) starts with the prefix **and** contains the required token, then pick the **newest by directory mtime**. Quick-reject the partition if the selected release lacks `<partition>_clocks.tcl`. (REF_MODEL/SDC example paths are illustrative — the designer symlinks the actual model; see §2.2.)

Verified on disk: imh/ioh use `H2B`; cbb0 releases carry no `H2B` token and use `CONTOUR` instead (e.g. `CORCBBPA0P05_CONTOUR_26WW27C_RTL26WW26C_V08`). Prefix filtering also excludes foreign-die releases that share a partition's `clock_collateral/` (e.g. `DMRIMH2A0_*` under IOH).

## 2.2 Symlink validation (pre-flight)

The designer pre-creates two symlinks as the run's starting point: `$WORKAREA/power/pprtl2/REF_MODEL` and `$WORKAREA/power/pprtl2/SDC_ARCHIVE`. Before generating anything, prep validates both and **fails fast** with a clear error if either is missing or malformed:
- each exists and resolves to a directory, **and**
- `REF_MODEL/output/<DUT>/partition/` exists, **and**
- `SDC_ARCHIVE/` contains at least one `<partition>/clock_collateral/` subdir.

Partition list file (per die, verified for imh/ioh/cbb0): `$WORKAREA/partition/<blocks.cfg>` per §2.1 (imh/ioh `<DUT>.blocks.cfg`, cbb0 `cbb0_h2b.blocks.cfg`).

## 3. Outputs (the generated tree)

With `$WORKAREA = /nfs/site/disks/.../corhub_oks-a0-pprtl2-partitions`:

```
$WORKAREA/power/pprtl2/
├── Makefile                                     # from S5 template (static wrapper → S4 include)
├── stdcell.ldb.list                             # from S3/S5
├── tool.cth                                     # cth config for the power run   (Q2)
├── activity_dir.map                             # verbatim copy (FE_ACTIVITY_MAPPING)
├── grdlbuild/                                   # verbatim copy of scripts/pprtl2/cor/grdlbuild
├── prep_pprtl2_partition.list                   # all non-skipped partitions, one per line
└── partition/
    ├── <partition>.flow.cfg                      # per partition, from S5 template
    └── <partition>/
        ├── hip.ldb.list.minimized               # minimizehip.pl on S1 hip ldb list
        ├── <partition>_clocks.tcl.fixclocks     # fixclocks.pl on S1 clock collateral
        └── elab.pre.tcl                          # elaboration pre-hook              (Q3)
```

---

## 4. Per-output derivation rules

**Per-partition gate:** any output with `<partition>` in its name is created only if **all three** exist. If any is missing, skip that partition's per-partition outputs (still record it in the report):

- **2stage filelist:** `$REF_MODEL/output/<DUT>/partition/<partition>/h2b/<sub>/fe_collateral/rtl_list_2stage.tcl`
- **hip ldb list:** `$REF_MODEL/output/<DUT>/partition/<partition>/h2b/<sub>/hip_collaterals/hip.ldb.list`
- **clocks.tcl:** `$SDC_ARCHIVE/<partition>/clock_collateral/<selected release>/<partition>_clocks.tcl` (release selected per die profile, §2.1)

where `<sub>` is the auto-detected h2b sublevel (§2.1).

**minimizehip disqualification (post-generation):** for an eligible partition, `minimizehip.pl` runs **first**. If the resulting `hip.ldb.list.minimized` reports `#HIPS_MISSING_LDB_OR_LIB_COUNT: N` with `N > 0` (some HIPs had no ldb/lib — a silent minimize failure), the partition is **disqualified**: `flow.cfg`, `elab.pre.tcl`, and `fixclocks` are **not** generated, it is excluded from `ran` and from `prep_pprtl2_partition.list`, and it is reported under the `fail minimizehip` category. The `hip.ldb.list.minimized` file is kept as evidence. Accounting: `total = ran + skipped + fail_minimizehip`.

The DUT-level static outputs (`Makefile`, `stdcell.ldb.list`, `tool.cth`, `activity_dir.map`, `grdlbuild/`) are always created regardless of per-partition gating.

**Report CSV** — `$WORKAREA/power/pprtl2/prep_pprtl2_report.csv`, columns:
`partition, 2stage_filelist_exists, hip_ldb_list_exists, clocks_tcl_exists, clock_release_used, created_hip_ldb_list_minimized, created_clocks_tcl_fixclocks, created_elab_pre_tcl, minimizehip_fail`.
`clock_release_used` = selected release dir name (§2.1), or `N/A` if the partition was skipped. `minimizehip_fail` = `yes`/`no` for eligible partitions, `N/A` for input-skipped ones.

**Report summary** — `$WORKAREA/power/pprtl2/prep_pprtl2_report.summary`, computed against **total partitions** (all percentages to 1 decimal place), with aligned columns:
- total partitions
- ran (all 3 inputs present AND minimizehip clean) + %
- skipped (≥1 input missing) + %
- missing 2stage + %, missing hiplist + %, missing clocks + % (counted independently)
- fail minimizehip + %

Followed by a bracketed section per category listing the partition names: `[missing 2stage]`, `[missing hiplist]`, `[missing clocks]`, `[fail minimizehip]`.

**Partition list** — `$WORKAREA/power/pprtl2/prep_pprtl2_partition.list`: every fully-generated (clean-run) partition, one per line, in blocks.cfg order. Excludes input-skipped and fail-minimizehip partitions.

| Output | Source | Transform |
|--------|--------|-----------|
| `Makefile` | S5 `scripts/pprtl2/cor/Makefile` | Copy verbatim (static; resolves `$CHEETAH_RTL_ROOT` at make time) |
| `stdcell.ldb.list` | S5 `scripts/pprtl2/cor/<DUT>/stdcell.ldb.list` | Copy the die-specific template (`cor/imh|ioh|cbb0/stdcell.ldb.list`) to `stdcell.ldb.list` |
| `tool.cth` | S5 `scripts/pprtl2/cor/tool.cth` | Copy verbatim |
| `activity_dir.map` | S5 `scripts/pprtl2/cor/activity_dir.map` | Copy verbatim (used as `FE_ACTIVITY_MAPPING`) |
| `grdlbuild/` | S5 `scripts/pprtl2/cor/grdlbuild/` | Copy the directory tree verbatim (overlay copy; NFS-safe, no rmtree). DUT is supplied to gradle at run time via `-Pdut=<DUT>`. |
| `partition/<partition>.flow.cfg` | S5 `scripts/pprtl2/cor/partition.flow.cfg` | Copy per partition, renamed to `<partition>.flow.cfg`. `${DUT}` / `${TOP_MODULE_NAME}` stay as make-time vars — **not** expanded by prep. |
| `partition/<partition>/hip.ldb.list.minimized` | `$REF_MODEL/output/<DUT>/partition/<partition>/h2b/<sub>/hip_collaterals/hip.ldb.list` | `minimizehip.pl <hip.ldb.list> <outdir>` where `<outdir>` = `$WORKAREA/power/pprtl2/partition/<partition>/`. Disqualifies the partition if `#HIPS_MISSING_LDB_OR_LIB_COUNT > 0`. |
| `partition/<partition>/<partition>_clocks.tcl.fixclocks` | `<selected release>` dir (§2.1) | `fixclocks.pl --module <partition> --clock-collateral-dir <release-dir>` run **with cwd = the partition output dir** (fixclocks writes `<partition>_clocks.tcl.fixclocks` into cwd). No `--tag`. |
| `partition/<partition>/elab.pre.tcl` | S5 `scripts/pprtl2/cor/elab.pre.tcl` | Copy per partition, verbatim (static template, present in `cor/`). |

---

## 5. CLI (proposed)

```
prep_pprtl2.py \
  --dut         {imh|ioh|cbb0}  # selects die profile (required)
  --workarea    <path>          # default: $WORKAREA
  --ref-model   <path|symlink>  # default: $WORKAREA/power/pprtl2/REF_MODEL
  --sdc-archive <path|symlink>  # default: $WORKAREA/power/pprtl2/SDC_ARCHIVE
  --partitions  <a,b,c>         # default: all from the die's blocks.cfg (§2.1)
  --blocks-cfg  <path>          # override the die's blocks.cfg path
  --templates   scripts/pprtl2/cor
  --clock-release-prefix <str>  # override die-profile prefix
  --clock-release-token  <str>  # override die-profile required token
  [--dry-run] [--force] [--verbose]
```

Behavior:
- `--dry-run` prints the planned actions/paths without writing.
- `--force` overwrites existing outputs; default refuses to clobber and reports.
- Validates every input exists before writing any output (fail fast, no partial trees).

---

## 6. Resolved questions & remaining notes

**Verified on disk (2026-07-11):** partition names match between `blocks.cfg` and `$SDC_ARCHIVE`; 2stage + hip paths confirmed under the `h2b/` level; `<partition>_clocks.tcl` and the clock params file present in the newest H2B release.

> **Note N1 — flow.cfg path drift (flag only, not fixed here):** the template [scripts/pprtl2/cor/partition.flow.cfg](scripts/pprtl2/cor/partition.flow.cfg) sets `H2B_TCL_FILE = $WORKAREA/REF_MODEL/output/${DUT}/partition/${TOP_MODULE_NAME}/trial/fe_collateral/rtl_list_2stage.tcl` — **missing the `h2b/` level** present in the real model. Confirm whether the template needs updating to `.../h2b/trial/fe_collateral/...`.
> ANSWER: update the template to include h2b/

> **Note N2 — "newest" release:** newest **by mtime** among `/h2b/i`-matching dirs resolves to `CORIMH_H2B_0P0/` for `paracccpc`, not the `WW24K` example. Confirm mtime is the intended tiebreaker (vs. lexical WW sort).
> ANSWER: yes, mtime is the intended tiebreaker.  The WW24K example was just a placeholder.

- **Q1** `stdcell.ldb.list`: copy the curated template as-is, or generate it from a stdcell root + rules?  Copied the curated template for now.  Will teach you how to generate it in the future.    This file changes very infrequently.
- **Q2** `tool.cth`: what are its contents/source for the power run? (Copy a template, or synthesize?)  Copy from `scripts/pprtl2/cor/tool.cth`
- **Q3** `elab.pre.tcl`: source and contents? Per-partition or shared?  Place this under power/pprtl2/partition/<partition>/
> ANSWER: copy from `scripts/pprtl2/cor/elab.pre.tcl` per partition.  This is a static template for now,  copy exact to power/pprtl2/partition/<partition>/
- **Q4** `minimizehip.pl` input: exact filename/glob of the hip ldb list inside `fe_collateral/` per partition.  minimizehip.pl <REF_MODEL>/output/<DUT>/partition/<partition>/trial/hip_collateral/<hip ldb list> <outdir>
- **Q5** `fixclocks.pl` invocation: required `--tag`, `--simple-sdc` vs `--clock-collateral-dir`, and the clock collateral path per partition.   Use --clock-collateral-dir.  See adjusted inputs above S7 on how to determine this directory.  I updated the script to not require --tag.  Don't use for now.
- **Q6** Partition source of truth: confirm `${DUT}.blocks.cfg` (`block_type = partition`) is the authoritative list, and whether gating/nongating variants matter here.  Use `${DUT}.blocks.cfg` as the initial list of partitions.  Ignore gating/nongating variants.

---

## 7. Test plan

Start small, table-driven, no live tool dependency in unit tests.

1. **Unit — partition parsing:** parse a fixture `blocks.cfg`, assert the expected
   partition set per the S2 rule (`hier_type = part`; else `block_type = partition` +
   `par` prefix; commented `#[...]` headers ignored).
2. **Unit — path derivation:** given `workarea/dut/ref-model/partition`, assert every
   output path and every expected source path string.
3. **Unit — template copy:** copy templates into a temp tree; assert content is byte-identical
   and `<partition>.flow.cfg` is named/placed correctly.
4. **Integration (mocked):** stub `minimizehip.pl` / `fixclocks.pl` with fakes that write
   sentinel files; assert the full tree is produced and `--dry-run` writes nothing.
5. **Smoke (manual/opt-in):** run against one real partition with the real REF_MODEL and
   diff against a known-good tree.

---

## 8. Implementation plan (phased)

- **Phase 0 (this spec):** approve scope + resolve Q1–Q6.
- **Phase 1:** `prep_pprtl2.py` skeleton — arg parsing, input validation, partition parsing
  from S2, `--dry-run` plan output. Unit tests 1–2. ✅ **DONE** — validated on all three dies
  ([prep_pprtl2.py](prep_pprtl2.py), [test_prep_pprtl2.py](test_prep_pprtl2.py)); dry-run results:
  imh 212/216, ioh 179/190, cbb0 43/47 partitions eligible.
- **Phase 2:** static outputs — `Makefile`, `stdcell.ldb.list`, `tool.cth`, per-partition
  `<partition>.flow.cfg`. Unit test 3. ✅ **DONE** — `${DUT}.stdcell.ldb.list` selected per die;
  `--force`/idempotent-skip handling; validated live on imh (215 outputs: 3 static + 212 flow.cfg).
- **Phase 3:** generated outputs — wire `minimizehip.pl` and `fixclocks.pl`; produce
  `hip.ldb.list.minimized`, `<partition>_clocks.tcl.fixclocks`, `elab.pre.tcl`. Integration test 4.
  ✅ **DONE** — injectable perl runners (mocked in test 4), per-partition gating, report CSV +
  summary; validated live on imh (fixclocks writes a `fixclocks.log` side file per partition dir).
- **Phase 4:** smoke run on one real partition; document usage in `scripts/pprtl2/cor/README.md`.
  ✅ **DONE** — full-die smoke on imh (187 partitions, ~23s, 0 errors); usage documented in
  [cor/README.md](cor/README.md). `activity_dir.map` + `grdlbuild/` added to the copy set;
  `minimizehip_fail` disqualification category added.

---

## 9. Non-goals (for now)

- Running the pprtl2 flow itself (only preparing the work area).
- Timebased power mode collateral (`.mtl`, `MTL_INST_TO_RUN`) — vectorless only.
- Multi-DUT orchestration beyond `imh`.
```
