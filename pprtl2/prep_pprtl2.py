#!/usr/bin/env python3
"""prep_pprtl2 — pprtl2 run-area preparation workflow.

Assembles a ready-to-run pprtl2 (RTL power analysis) work area under
``$WORKAREA/power/pprtl2/`` by collecting collateral from a GK reference model,
a clock-SDC model, in-repo templates, and the partition/blocks config.

See scripts/pprtl2/prep_pprtl2.spec.md for the full specification.

Phase 1 scope (this file): die profiles, CLI, symlink validation, blocks.cfg
partition parsing, clock-release selection, per-partition input gating, and the
``--dry-run`` plan. The actual output-generation steps (template copies and the
minimizehip.pl / fixclocks.pl subprocess calls) are implemented in later phases;
they raise ``NotImplementedError`` if invoked before then.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path


# --------------------------------------------------------------------------- #
# Die profiles (spec section 2.1)
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class DieProfile:
    """Per-die clock-release selection filter."""

    dut: str
    clock_release_prefix: str
    clock_release_token: str
    blocks_cfg_name: str


DIE_PROFILES: dict[str, DieProfile] = {
    "imh": DieProfile(
        dut="imh", clock_release_prefix="CORIMH", clock_release_token="H2B",
        blocks_cfg_name="imh.blocks.cfg",
    ),
    "ioh": DieProfile(
        dut="ioh", clock_release_prefix="CORIOH", clock_release_token="H2B",
        blocks_cfg_name="ioh.blocks.cfg",
    ),
    "cbb0": DieProfile(
        dut="cbb0", clock_release_prefix="CORCBBP", clock_release_token="CONTOUR",
        blocks_cfg_name="cbb0_h2b.blocks.cfg",
    ),
}


# --------------------------------------------------------------------------- #
# Resolved run configuration
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Config:
    """Fully-resolved run configuration (all paths absolute)."""

    dut: str
    workarea: Path
    ref_model: Path
    sdc_archive: Path
    templates: Path
    profile: DieProfile
    partitions: list[str] | None  # None => derive from blocks.cfg
    blocks_cfg_override: Path | None = None

    @property
    def out_root(self) -> Path:
        return self.workarea / "power" / "pprtl2"

    @property
    def blocks_cfg(self) -> Path:
        if self.blocks_cfg_override is not None:
            return self.blocks_cfg_override
        return self.workarea / "partition" / self.profile.blocks_cfg_name

    @property
    def report_csv(self) -> Path:
        return self.out_root / "prep_pprtl2_report.csv"

    @property
    def report_summary(self) -> Path:
        return self.out_root / "prep_pprtl2_report.summary"

    @property
    def partition_list(self) -> Path:
        return self.out_root / "prep_pprtl2_partition.list"


# --------------------------------------------------------------------------- #
# Per-partition derived paths (pure; no disk access)
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class PartitionPaths:
    """All source and output paths for one partition.

    ``clock_release`` is the selected release directory *name* (or ``None`` when
    no matching release was found); the clock paths are only meaningful when it
    is set.
    """

    partition: str
    clock_release: str | None
    h2b_subdir: str | None

    # sources (ref_* are None when the h2b sublevel can't be resolved)
    ref_2stage: Path | None
    ref_hip: Path | None
    clock_release_dir: Path | None
    clock_tcl: Path | None

    # outputs
    part_out_dir: Path
    flow_cfg: Path
    hip_minimized: Path
    clocks_fixclocks: Path
    elab_pre_tcl: Path


def derive_partition_paths(
    cfg: Config,
    partition: str,
    clock_release: str | None,
    h2b_subdir: str | None,
) -> PartitionPaths:
    """Derive every source/output path for ``partition`` (no disk access).

    ``h2b_subdir`` is the resolved sublevel under ``h2b/`` (e.g. ``trial`` for
    imh/ioh, ``cbb0`` for cbb0). When ``None`` the reference collateral paths
    are unknown and returned as ``None``.
    """
    if h2b_subdir is not None:
        ref_base = (
            cfg.ref_model / "output" / cfg.dut / "partition" / partition / "h2b" / h2b_subdir
        )
        ref_2stage: Path | None = ref_base / "fe_collateral" / "rtl_list_2stage.tcl"
        ref_hip: Path | None = ref_base / "hip_collaterals" / "hip.ldb.list"
    else:
        ref_2stage = None
        ref_hip = None

    if clock_release is not None:
        clock_release_dir: Path | None = (
            cfg.sdc_archive / partition / "clock_collateral" / clock_release
        )
        clock_tcl: Path | None = clock_release_dir / f"{partition}_clocks.tcl"
    else:
        clock_release_dir = None
        clock_tcl = None

    part_out_dir = cfg.out_root / "partition" / partition
    return PartitionPaths(
        partition=partition,
        clock_release=clock_release,
        h2b_subdir=h2b_subdir,
        ref_2stage=ref_2stage,
        ref_hip=ref_hip,
        clock_release_dir=clock_release_dir,
        clock_tcl=clock_tcl,
        part_out_dir=part_out_dir,
        flow_cfg=cfg.out_root / "partition" / f"{partition}.flow.cfg",
        hip_minimized=part_out_dir / "hip.ldb.list.minimized",
        clocks_fixclocks=part_out_dir / f"{partition}_clocks.tcl.fixclocks",
        elab_pre_tcl=part_out_dir / "elab.pre.tcl",
    )


# --------------------------------------------------------------------------- #
# blocks.cfg parsing (spec section 2, S2)
# --------------------------------------------------------------------------- #
_SECTION_RE = re.compile(r"^\s*\[(?P<name>[^\]]+)\]\s*$")
_HIER_TYPE_RE = re.compile(r"^\s*hier_type\s*=\s*(?P<value>\S+)\s*$")
_BLOCK_TYPE_RE = re.compile(r"^\s*block_type\s*=\s*(?P<value>\S+)\s*$")


def parse_partitions(blocks_cfg: Path) -> list[str]:
    """Return partition section names, in file order.

    The blocks.cfg is an INI-like file: ``[name]`` opens a section. A section is
    a partition when its ``hier_type`` is ``part``; if the file uses no
    ``hier_type`` field at all (e.g. ioh/cbb0), fall back to
    ``block_type == partition`` **and** a name starting with ``par``. Comment
    lines are ignored, and a commented-out section header (e.g.
    ``#[parsocsouth0chassis]``) ends the current section so its stray keys are
    not misattributed.
    """
    if not blocks_cfg.is_file():
        raise FileNotFoundError(f"blocks.cfg not found: {blocks_cfg}")

    names: list[str] = []
    seen: set[str] = set()
    block_type: dict[str, str] = {}
    hier_type: dict[str, str] = {}
    current: str | None = None

    with blocks_cfg.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            stripped = line.lstrip()
            if stripped.startswith("#"):
                # A commented-out section header ends the current section.
                if _SECTION_RE.match(stripped.lstrip("#").strip()):
                    current = None
                continue
            m = _SECTION_RE.match(line)
            if m:
                current = m.group("name").strip()
                if current not in seen:
                    seen.add(current)
                    names.append(current)
                continue
            if current is None:
                continue
            bt = _BLOCK_TYPE_RE.match(line)
            if bt:
                block_type[current] = bt.group("value")
                continue
            ht = _HIER_TYPE_RE.match(line)
            if ht:
                hier_type[current] = ht.group("value")

    if hier_type:  # file uses hier_type => authoritative
        return [n for n in names if hier_type.get(n) == "part"]
    # Fallback (no hier_type field, e.g. ioh/cbb0): block_type == partition and
    # a name starting with "par".
    return [n for n in names if block_type.get(n) == "partition" and n.startswith("par")]


# --------------------------------------------------------------------------- #
# Clock-release selection (spec section 2.1; touches disk)
# --------------------------------------------------------------------------- #
def select_clock_release(sdc_archive: Path, partition: str, prefix: str, token: str) -> str | None:
    """Pick the newest (by mtime) clock release for ``partition``.

    Keeps release dirs whose name (case-insensitive) starts with ``prefix`` and
    contains ``token``; returns the newest by directory mtime, or ``None``.
    """
    cc_dir = sdc_archive / partition / "clock_collateral"
    if not cc_dir.is_dir():
        return None
    prefix_u = prefix.upper()
    token_u = token.upper()
    candidates = [
        d
        for d in cc_dir.iterdir()
        if d.is_dir() and d.name.upper().startswith(prefix_u) and token_u in d.name.upper()
    ]
    if not candidates:
        return None
    newest = max(candidates, key=lambda d: d.stat().st_mtime)
    return newest.name


def resolve_h2b_subdir(ref_model: Path, dut: str, partition: str) -> str | None:
    """Resolve the sublevel under ``h2b/`` for a partition.

    Prefers ``h2b/trial``; otherwise, if ``h2b/`` contains exactly one subdir,
    uses it. Returns ``None`` if ``h2b/`` is missing or ambiguous (0 or >1
    subdirs and no ``trial``).
    """
    h2b_dir = ref_model / "output" / dut / "partition" / partition / "h2b"
    if not h2b_dir.is_dir():
        return None
    if (h2b_dir / "trial").is_dir():
        return "trial"
    subdirs = [d.name for d in h2b_dir.iterdir() if d.is_dir()]
    if len(subdirs) == 1:
        return subdirs[0]
    return None


# --------------------------------------------------------------------------- #
# Symlink validation (spec section 2.2)
# --------------------------------------------------------------------------- #
def validate_models(cfg: Config) -> list[str]:
    """Return a list of validation error strings (empty => valid)."""
    errors: list[str] = []

    ref = cfg.ref_model
    if not ref.exists():
        errors.append(f"REF_MODEL does not exist: {ref}")
    elif not ref.is_dir():
        errors.append(f"REF_MODEL does not resolve to a directory: {ref}")
    else:
        ref_part = ref / "output" / cfg.dut / "partition"
        if not ref_part.is_dir():
            errors.append(f"REF_MODEL missing 'output/{cfg.dut}/partition/': {ref_part}")

    sdc = cfg.sdc_archive
    if not sdc.exists():
        errors.append(f"SDC_ARCHIVE does not exist: {sdc}")
    elif not sdc.is_dir():
        errors.append(f"SDC_ARCHIVE does not resolve to a directory: {sdc}")
    else:
        has_cc = any(
            (child / "clock_collateral").is_dir() for child in sdc.iterdir() if child.is_dir()
        )
        if not has_cc:
            errors.append(
                f"SDC_ARCHIVE has no '<partition>/clock_collateral/' subdir: {sdc}"
            )

    return errors


# --------------------------------------------------------------------------- #
# Plan model
# --------------------------------------------------------------------------- #
@dataclass
class PartitionPlan:
    """Existence gating + derived paths for one partition."""

    paths: PartitionPaths
    has_2stage: bool
    has_hip: bool
    has_clocks: bool

    @property
    def eligible(self) -> bool:
        return self.has_2stage and self.has_hip and self.has_clocks


@dataclass
class RunPlan:
    cfg: Config
    partitions: list[PartitionPlan] = field(default_factory=list)

    @property
    def ran(self) -> list[PartitionPlan]:
        return [p for p in self.partitions if p.eligible]

    @property
    def skipped(self) -> list[PartitionPlan]:
        return [p for p in self.partitions if not p.eligible]


def build_plan(cfg: Config, partitions: list[str]) -> RunPlan:
    """Compute the per-partition gating plan (touches disk for existence checks)."""
    plan = RunPlan(cfg=cfg)
    for partition in partitions:
        release = select_clock_release(
            cfg.sdc_archive,
            partition,
            cfg.profile.clock_release_prefix,
            cfg.profile.clock_release_token,
        )
        h2b_subdir = resolve_h2b_subdir(cfg.ref_model, cfg.dut, partition)
        paths = derive_partition_paths(cfg, partition, release, h2b_subdir)
        has_2stage = paths.ref_2stage is not None and paths.ref_2stage.is_file()
        has_hip = paths.ref_hip is not None and paths.ref_hip.is_file()
        has_clocks = paths.clock_tcl is not None and paths.clock_tcl.is_file()
        plan.partitions.append(
            PartitionPlan(
                paths=paths,
                has_2stage=has_2stage,
                has_hip=has_hip,
                has_clocks=has_clocks,
            )
        )
    return plan


# --------------------------------------------------------------------------- #
# Dry-run rendering
# --------------------------------------------------------------------------- #
def _pct(count: int, total: int) -> str:
    return f"{(100.0 * count / total):.1f}%" if total else "0.0%"


def render_plan(plan: RunPlan) -> str:
    cfg = plan.cfg
    lines: list[str] = []
    lines.append(f"prep_pprtl2 dry-run plan  (dut={cfg.dut})")
    lines.append(f"  workarea : {cfg.workarea}")
    lines.append(f"  ref_model: {cfg.ref_model}")
    lines.append(f"  sdc_archive: {cfg.sdc_archive}")
    lines.append(f"  templates: {cfg.templates}")
    lines.append(f"  out_root : {cfg.out_root}")
    lines.append(
        f"  clock filter: startswith '{cfg.profile.clock_release_prefix}' "
        f"and contains '{cfg.profile.clock_release_token}', newest by mtime"
    )
    lines.append("")
    lines.append("DUT-level outputs (always):")
    lines.append(f"  + {cfg.out_root / 'Makefile'}  <- {cfg.templates / 'Makefile'}")
    lines.append(
        f"  + {cfg.out_root / 'stdcell.ldb.list'}  <- "
        f"{cfg.templates / cfg.dut / 'stdcell.ldb.list'}"
    )
    lines.append(f"  + {cfg.out_root / 'tool.cth'}  <- {cfg.templates / 'tool.cth'}")
    lines.append(
        f"  + {cfg.out_root / 'activity_dir.map'}  <- {cfg.templates / 'activity_dir.map'}"
    )
    lines.append("")
    lines.append(f"Partitions: {len(plan.partitions)} total")
    for p in plan.partitions:
        flags = (
            f"2stage={'Y' if p.has_2stage else 'N'} "
            f"hip={'Y' if p.has_hip else 'N'} "
            f"clocks={'Y' if p.has_clocks else 'N'}"
        )
        status = "RUN " if p.eligible else "SKIP"
        rel = p.paths.clock_release or "N/A"
        lines.append(f"  [{status}] {p.paths.partition}  ({flags}; release={rel})")
    lines.append("")

    total = len(plan.partitions)
    ran = len(plan.ran)
    skipped = len(plan.skipped)
    miss_2stage = sum(1 for p in plan.partitions if not p.has_2stage)
    miss_hip = sum(1 for p in plan.partitions if not p.has_hip)
    miss_clocks = sum(1 for p in plan.partitions if not p.has_clocks)
    lines.append("Summary:")
    lines.append(f"  total partitions : {total}")
    lines.append(f"  ran              : {ran} ({_pct(ran, total)})")
    lines.append(f"  skipped          : {skipped} ({_pct(skipped, total)})")
    lines.append(f"  missing 2stage   : {miss_2stage} ({_pct(miss_2stage, total)})")
    lines.append(f"  missing hip      : {miss_hip} ({_pct(miss_hip, total)})")
    lines.append(f"  missing clocks   : {miss_clocks} ({_pct(miss_clocks, total)})")
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Execution (Phase 2: static outputs + per-partition flow.cfg)
# --------------------------------------------------------------------------- #
@dataclass
class WriteOutcome:
    """Accumulates which output files were created / overwritten / skipped."""

    created: list[Path] = field(default_factory=list)
    overwritten: list[Path] = field(default_factory=list)
    skipped_exist: list[Path] = field(default_factory=list)


def _copy_template(src: Path, dst: Path, force: bool, outcome: WriteOutcome, verbose: bool) -> None:
    """Copy ``src`` -> ``dst`` verbatim, honoring ``force`` for existing files."""
    if not src.is_file():
        raise FileNotFoundError(f"template not found: {src}")
    if dst.exists():
        if not force:
            outcome.skipped_exist.append(dst)
            if verbose:
                print(f"-I- exists, skipped (use --force to overwrite): {dst}")
            return
        outcome.overwritten.append(dst)
    else:
        outcome.created.append(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
    if verbose:
        print(f"-I- wrote {dst}")


def _copy_tree(src: Path, dst: Path, force: bool, outcome: WriteOutcome, verbose: bool) -> None:
    """Copy the directory tree ``src`` -> ``dst`` verbatim, honoring ``force``.

    Uses an overlay copy (``dirs_exist_ok=True``) rather than removing ``dst``
    first: rmtree is unsafe on NFS when a file in ``dst`` is held open (it
    leaves ``.nfs*`` artifacts and a partially-deleted tree).
    """
    if not src.is_dir():
        raise FileNotFoundError(f"template dir not found: {src}")
    existed = dst.exists()
    if existed and not force:
        outcome.skipped_exist.append(dst)
        if verbose:
            print(f"-I- exists, skipped (use --force to overwrite): {dst}/")
        return
    shutil.copytree(src, dst, dirs_exist_ok=True)
    (outcome.overwritten if existed else outcome.created).append(dst)
    if verbose:
        print(f"-I- wrote {dst}/")


def _scripts_dir() -> Path:
    """Directory holding this script and the perl helpers."""
    return Path(__file__).resolve().parent


@dataclass
class PartitionResult:
    """Per-partition gating + generated-output status (for the report)."""

    partition: str
    has_2stage: bool
    has_hip: bool
    has_clocks: bool
    clock_release: str | None
    created_hip_minimized: bool = False
    created_clocks_fixclocks: bool = False
    created_elab_pre_tcl: bool = False
    minimizehip_fail: bool = False
    hips_missing_ldb_count: int | None = None
    errors: list[str] = field(default_factory=list)

    @property
    def eligible(self) -> bool:
        """All three required inputs are present (gate for running minimizehip)."""
        return self.has_2stage and self.has_hip and self.has_clocks

    @property
    def ran_clean(self) -> bool:
        """Eligible AND minimizehip reported no missing ldb/lib (fully generated)."""
        return self.eligible and not self.minimizehip_fail


@dataclass
class ExecReport:
    outcome: "WriteOutcome"
    results: list[PartitionResult] = field(default_factory=list)


MinimizeFn = Callable[[Path, Path | None, Path], subprocess.CompletedProcess]
FixclocksFn = Callable[[Path, str, Path | None, Path], subprocess.CompletedProcess]


def execute_plan(
    plan: RunPlan,
    force: bool,
    verbose: bool,
    *,
    minimize: "MinimizeFn" = None,  # type: ignore[assignment]
    fixclocks: "FixclocksFn" = None,  # type: ignore[assignment]
) -> "ExecReport":
    """Create all outputs (Phase 2 static + Phase 3 generated) and write reports.

    ``minimize`` / ``fixclocks`` are injectable runners (defaulting to the real
    perl helpers) so tests can mock the subprocess calls.
    """
    if minimize is None:
        minimize = run_minimizehip
    if fixclocks is None:
        fixclocks = run_fixclocks

    cfg = plan.cfg
    scripts = _scripts_dir()
    outcome = WriteOutcome()
    cfg.out_root.mkdir(parents=True, exist_ok=True)

    # DUT-level static outputs (always)
    _copy_template(cfg.templates / "Makefile", cfg.out_root / "Makefile", force, outcome, verbose)
    _copy_template(
        cfg.templates / cfg.dut / "stdcell.ldb.list",
        cfg.out_root / "stdcell.ldb.list",
        force,
        outcome,
        verbose,
    )
    _copy_template(cfg.templates / "tool.cth", cfg.out_root / "tool.cth", force, outcome, verbose)
    _copy_template(
        cfg.templates / "activity_dir.map",
        cfg.out_root / "activity_dir.map",
        force,
        outcome,
        verbose,
    )
    _copy_tree(cfg.templates / "grdlbuild", cfg.out_root / "grdlbuild", force, outcome, verbose)

    flow_tmpl = cfg.templates / "partition.flow.cfg"
    elab_tmpl = cfg.templates / "elab.pre.tcl"

    results: list[PartitionResult] = []
    for pplan in plan.partitions:
        paths = pplan.paths
        res = PartitionResult(
            partition=paths.partition,
            has_2stage=pplan.has_2stage,
            has_hip=pplan.has_hip,
            has_clocks=pplan.has_clocks,
            clock_release=paths.clock_release,
        )
        if pplan.eligible:
            assert paths.ref_hip is not None and paths.clock_release_dir is not None
            paths.part_out_dir.mkdir(parents=True, exist_ok=True)
            # Generate hip.ldb.list.minimized first; its result gates the rest.
            res.created_hip_minimized = _generate(
                "minimizehip",
                paths.hip_minimized,
                force,
                verbose,
                res,
                lambda p=paths: minimize(scripts, p.ref_hip, p.part_out_dir),
            )
            if res.created_hip_minimized:
                res.hips_missing_ldb_count = _parse_missing_ldb_count(paths.hip_minimized)
            res.minimizehip_fail = bool(res.hips_missing_ldb_count)
            if not res.minimizehip_fail:
                # Fully generate: per-partition static copies + clock collateral.
                _copy_template(flow_tmpl, paths.flow_cfg, force, outcome, verbose)
                _copy_template(elab_tmpl, paths.elab_pre_tcl, force, outcome, verbose)
                res.created_elab_pre_tcl = paths.elab_pre_tcl.is_file()
                res.created_clocks_fixclocks = _generate(
                    "fixclocks",
                    paths.clocks_fixclocks,
                    force,
                    verbose,
                    res,
                    lambda p=paths: fixclocks(
                        scripts, p.partition, p.clock_release_dir, p.part_out_dir
                    ),
                )
        results.append(res)

    report = ExecReport(outcome=outcome, results=results)
    _write_reports(cfg, report)
    return report


def _generate(
    kind: str,
    out_path: Path,
    force: bool,
    verbose: bool,
    res: "PartitionResult",
    runner: "Callable[[], subprocess.CompletedProcess]",
) -> bool:
    """Run one generator (unless the output already exists and not ``force``).

    Returns whether the output file is present afterward.
    """
    if out_path.is_file() and not force:
        if verbose:
            print(f"-I- exists, skipped (use --force): {out_path}")
        return True
    proc = runner()
    if proc.returncode != 0:
        msg = (proc.stderr or proc.stdout or "").strip().splitlines()
        res.errors.append(f"{kind} failed (rc={proc.returncode}): {msg[-1] if msg else ''}")
    elif verbose:
        print(f"-I- wrote {out_path}")
    return out_path.is_file()


def run_minimizehip(
    scripts_dir: Path, ref_hip: Path | None, out_dir: Path
) -> subprocess.CompletedProcess:
    """Run minimizehip.pl <ref_hip> <out_dir> (writes hip.ldb.list.minimized)."""
    cmd = [str(scripts_dir / "minimizehip.pl"), str(ref_hip), str(out_dir)]
    return subprocess.run(cmd, capture_output=True, text=True)


def run_fixclocks(
    scripts_dir: Path, partition: str, clock_release_dir: Path | None, cwd: Path
) -> subprocess.CompletedProcess:
    """Run fixclocks.pl in ``cwd`` (writes <partition>_clocks.tcl.fixclocks)."""
    cmd = [
        str(scripts_dir / "fixclocks.pl"),
        "--module",
        partition,
        "--clock-collateral-dir",
        str(clock_release_dir),
    ]
    return subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)


_MISSING_LDB_RE = re.compile(r"^#HIPS_MISSING_LDB_OR_LIB_COUNT:\s*(\d+)")


def _parse_missing_ldb_count(minimized: Path) -> int | None:
    """Return the ``#HIPS_MISSING_LDB_OR_LIB_COUNT`` value from a minimized file.

    minimizehip.pl writes this tag; a value > 0 means some HIPs had no ldb/lib
    (a silent minimize failure). Returns ``None`` if the file/tag is absent.
    """
    if not minimized.is_file():
        return None
    for line in minimized.read_text(encoding="utf-8", errors="replace").splitlines():
        m = _MISSING_LDB_RE.match(line.strip())
        if m:
            return int(m.group(1))
    return None


REPORT_COLUMNS = [
    "partition",
    "2stage_filelist_exists",
    "hip_ldb_list_exists",
    "clocks_tcl_exists",
    "clock_release_used",
    "created_hip_ldb_list_minimized",
    "created_clocks_tcl_fixclocks",
    "created_elab_pre_tcl",
    "minimizehip_fail",
]


def _yn(value: bool) -> str:
    return "yes" if value else "no"


def _write_reports(cfg: Config, report: "ExecReport") -> None:
    """Write the per-partition CSV and the summary file."""
    with cfg.report_csv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(REPORT_COLUMNS)
        for r in report.results:
            writer.writerow(
                [
                    r.partition,
                    _yn(r.has_2stage),
                    _yn(r.has_hip),
                    _yn(r.has_clocks),
                    r.clock_release or "N/A",
                    _yn(r.created_hip_minimized),
                    _yn(r.created_clocks_fixclocks),
                    _yn(r.created_elab_pre_tcl),
                    ("yes" if r.minimizehip_fail else "no") if r.eligible else "N/A",
                ]
            )

    total = len(report.results)
    ran = sum(1 for r in report.results if r.ran_clean)
    skipped = sum(1 for r in report.results if not r.eligible)
    miss_2stage = [r.partition for r in report.results if not r.has_2stage]
    miss_hiplist = [r.partition for r in report.results if not r.has_hip]
    miss_clocks = [r.partition for r in report.results if not r.has_clocks]
    fail_min = [r.partition for r in report.results if r.minimizehip_fail]

    def stat(label: str, count: int) -> str:
        return f"{label:<16} : {count} ({_pct(count, total)})"

    lines = [
        f"prep_pprtl2 report summary (dut={cfg.dut})",
        f"{'total partitions':<16} : {total}",
        stat("ran", ran),
        stat("skipped", skipped),
        stat("missing 2stage", len(miss_2stage)),
        stat("missing hiplist", len(miss_hiplist)),
        stat("missing clocks", len(miss_clocks)),
        stat("fail minimizehip", len(fail_min)),
    ]
    for title, names in (
        ("missing 2stage", miss_2stage),
        ("missing hiplist", miss_hiplist),
        ("missing clocks", miss_clocks),
        ("fail minimizehip", fail_min),
    ):
        lines.append("")
        lines.append(f"[{title}] ({len(names)})")
        lines.extend(f"  {name}" for name in names)
    cfg.report_summary.write_text("\n".join(lines) + "\n", encoding="utf-8")

    # prep_pprtl2_partition.list: all fully-generated (clean) partitions, one per line.
    eligible = [r.partition for r in report.results if r.ran_clean]
    cfg.partition_list.write_text(
        "".join(f"{name}\n" for name in eligible), encoding="utf-8"
    )


def render_execution(plan: RunPlan, report: "ExecReport") -> str:
    outcome = report.outcome
    total = len(report.results)
    ran = sum(1 for r in report.results if r.ran_clean)
    skipped = sum(1 for r in report.results if not r.eligible)
    fail_min = sum(1 for r in report.results if r.minimizehip_fail)
    hip_ok = sum(1 for r in report.results if r.created_hip_minimized)
    clk_ok = sum(1 for r in report.results if r.created_clocks_fixclocks)
    elab_ok = sum(1 for r in report.results if r.created_elab_pre_tcl)
    errored = [r for r in report.results if r.errors]
    lines = [
        f"prep_pprtl2 (dut={plan.cfg.dut})  out_root: {plan.cfg.out_root}",
        f"  static/flow/elab files : created={len(outcome.created)} "
        f"overwritten={len(outcome.overwritten)} skipped={len(outcome.skipped_exist)}",
        f"  partitions             : {total} total, {ran} ran ({_pct(ran, total)}), "
        f"{skipped} skipped, {fail_min} fail minimizehip",
        f"  hip.ldb.list.minimized : {hip_ok}",
        f"  *_clocks.tcl.fixclocks : {clk_ok}/{ran}",
        f"  elab.pre.tcl           : {elab_ok}/{ran}",
        f"  partitions with errors : {len(errored)}",
        f"  partition.list : {plan.cfg.partition_list}",
        f"  report  : {plan.cfg.report_csv}",
        f"  summary : {plan.cfg.report_summary}",
    ]
    for r in errored[:10]:
        for e in r.errors:
            lines.append(f"    -E- {r.partition}: {e}")
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def _default_templates() -> Path:
    return Path(__file__).resolve().parent / "cor"


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="prep_pprtl2.py",
        description="Prepare a pprtl2 run area from reference/SDC models and templates.",
    )
    parser.add_argument(
        "--dut", required=True, choices=sorted(DIE_PROFILES), help="Die / DUT profile to use."
    )
    parser.add_argument(
        "--workarea",
        type=Path,
        default=None,
        help="Work area root (default: $WORKAREA).",
    )
    parser.add_argument(
        "--ref-model",
        type=Path,
        default=None,
        help="GK reference model (default: <workarea>/power/pprtl2/REF_MODEL).",
    )
    parser.add_argument(
        "--sdc-archive",
        type=Path,
        default=None,
        help="Clock SDC archive (default: <workarea>/power/pprtl2/SDC_ARCHIVE).",
    )
    parser.add_argument(
        "--partitions",
        default=None,
        help="Comma-separated partitions (default: all from <workarea>/partition/<dut>.blocks.cfg).",
    )
    parser.add_argument(
        "--blocks-cfg",
        type=Path,
        default=None,
        help="Override partition blocks.cfg path (default: <workarea>/partition/<profile blocks cfg>).",
    )
    parser.add_argument(
        "--templates",
        type=Path,
        default=None,
        help="Template dir (default: <script dir>/cor).",
    )
    parser.add_argument(
        "--clock-release-prefix",
        default=None,
        help="Override die-profile clock-release prefix.",
    )
    parser.add_argument(
        "--clock-release-token",
        default=None,
        help="Override die-profile clock-release required token.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print the plan; write nothing.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing outputs.")
    parser.add_argument("--verbose", action="store_true", help="Verbose logging.")
    return parser


def resolve_config(args: argparse.Namespace) -> Config:
    workarea = args.workarea or (Path(os.environ["WORKAREA"]) if "WORKAREA" in os.environ else None)
    if workarea is None:
        raise SystemExit("-E- --workarea not given and $WORKAREA is not set.")
    workarea = workarea.resolve()

    ref_model = (args.ref_model or (workarea / "power" / "pprtl2" / "REF_MODEL")).resolve()
    sdc_archive = (args.sdc_archive or (workarea / "power" / "pprtl2" / "SDC_ARCHIVE")).resolve()
    templates = (args.templates or _default_templates()).resolve()

    base = DIE_PROFILES[args.dut]
    profile = DieProfile(
        dut=base.dut,
        clock_release_prefix=args.clock_release_prefix or base.clock_release_prefix,
        clock_release_token=args.clock_release_token or base.clock_release_token,
        blocks_cfg_name=base.blocks_cfg_name,
    )

    partitions = None
    if args.partitions:
        partitions = [p.strip() for p in args.partitions.split(",") if p.strip()]

    blocks_cfg_override = args.blocks_cfg.resolve() if args.blocks_cfg else None

    return Config(
        dut=args.dut,
        workarea=workarea,
        ref_model=ref_model,
        sdc_archive=sdc_archive,
        templates=templates,
        profile=profile,
        partitions=partitions,
        blocks_cfg_override=blocks_cfg_override,
    )


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)
    cfg = resolve_config(args)

    errors = validate_models(cfg)
    if errors:
        for e in errors:
            print(f"-E- {e}", file=sys.stderr)
        return 2

    partitions = cfg.partitions if cfg.partitions is not None else parse_partitions(cfg.blocks_cfg)
    if not partitions:
        print("-E- No partitions to process.", file=sys.stderr)
        return 2

    plan = build_plan(cfg, partitions)

    if args.dry_run:
        print(render_plan(plan))
        return 0

    report = execute_plan(plan, args.force, args.verbose)
    print(render_execution(plan, report))
    return 1 if any(r.errors for r in report.results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
