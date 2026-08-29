#!/usr/bin/env python3
"""report_pprtl2 — pprtl2 run-area summary/report generator.

Scans a pprtl2 (RTL power analysis) run area under ``$WORKAREA/output/<dut>/``
and produces machine- and human-readable rollup reports under
``$WORKAREA/power/pprtl2/``.

See scripts/pprtl2/report_pprtl2.spec.md for the full specification, and
scripts/pprtl2/report_pprtl2.py's companion test file for fixture-driven unit
tests of every pure-parsing function.

Deviations from the spec text, verified against real workareas on disk
(see /memories/repo/report_pprtl2.md):
  - The partition-style layout is ``output/<dut>/partition/<module>/pprtl2/<pass>/``
    (spec text says ``pprtl/``). Both this and the flat
    ``output/<dut>/pprtl2/<pass>/`` layout can be present in the same workarea
    (per-module, not per-workarea) -- both are probed.
  - flow_inputs/config.log is an ASCII box-drawing table, not key=value.
  - fsdb sources are nested per test+instance:
    ``fsdb/<test_name>/<instance>/{fsdb.PASS,log/flow.log}``.
  - Each row (module, power_mode, test_name) also carries an ``instance``
    column (not in the spec's CSV column list) because real timebased runs
    key their reports/logs by ``<test_name>/<instance>``, and instance is not
    always redundant with module/test_name.
  - Netbatch "Rusage ... Mem:<n>" field is in MB (user-confirmed); converted
    to GB via ``n / 1000``.
  - Status (Pass/Fail=<n>/Running/Not Started) is grdlbuild-log-only truth
    (2026-08-11): the grdlbuild netbatch job log at
    ``output/grdlbuild_power/logs/power.<module>.pprtl2_<activity>.log`` is the
    SOLE source -- ``.PASS`` marker files are no longer consulted. elab, fsdb,
    and timebased power are each ONE grdlbuild task per module (not per test),
    so their status is computed once and shared across every test row of that
    module. flow.log is only used as a runtime/memory fallback.
  - QoR fields (2026-08-12) come primarily from ``<module>.rtl_metrics.hier.csv``
    (S25) -- it wins over stat2.rpt too, and the old cells.rpt/power_groups.rpt/
    cge.hier.rpt sources have been retired entirely. Only the module's own
    top-of-hierarchy row (``Hierarchy Level`` == "0", matched by Module Name)
    is read, and the parser stops as soon as it finds that row instead of
    scanning the whole (often 10000+ row) file. stat2.rpt now only supplies
    the timebased-only annotation fields (annotation_primary_io/annotation_bb/
    annotation_seq); untraced_sequentials_percentage is always calculated from
    rtl_metrics' register/unclocked_sequential cell counts. VCS_VERSION/VERDI_VERSION/
    PPRTL_VERSION are module-level (one elab run per module) and come from
    vcs.log (S6) and the elab grdlbuild log (S2) respectively.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


# --------------------------------------------------------------------------- #
# Config
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class Config:
    """Fully-resolved run configuration."""

    dut: str
    workarea: Path

    @property
    def out_root(self) -> Path:
        return self.workarea / "power" / "pprtl2"

    @property
    def summary(self) -> Path:
        return self.out_root / "report_pprtl2.summary"

    @property
    def compute_csv(self) -> Path:
        return self.out_root / "report_pprtl2.compute.csv"

    @property
    def qor_csv(self) -> Path:
        return self.out_root / "report_pprtl2.qor.csv"

    @property
    def fail_details(self) -> Path:
        return self.out_root / "report_pprtl2.fail.details"

    @property
    def readme(self) -> Path:
        return self.out_root / "report_pprtl2.README"

    @property
    def ref_model(self) -> Path:
        return self.out_root / "REF_MODEL"

    @property
    def sdc_archive(self) -> Path:
        return self.out_root / "SDC_ARCHIVE"

    @property
    def mtl_file(self) -> Path:
        return self.out_root / "MTL_FILE"

    @property
    def report_summary(self) -> Path:
        return self.out_root / "prep_pprtl2_report.summary"

    @property
    def partition_list(self) -> Path:
        return self.out_root / "prep_pprtl2_partition.list"

    @property
    def timebased_partition_list(self) -> Path:
        return self.out_root / "prep_pprtl2_timebased_partition.list"


# --------------------------------------------------------------------------- #
# Generic small helpers
# --------------------------------------------------------------------------- #
def _read(path: Path | None) -> str | None:
    if path is None or not path.is_file():
        return None
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def _to_int(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        return int(str(value).replace(",", "").strip())
    except ValueError:
        return None


def _to_float(value: str | None) -> float | None:
    if value is None:
        return None
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return None


def _blank(value):
    return "" if value is None else value


def fmt_mem(gb: float | None) -> str:
    return "" if gb is None else f"{gb:.2f} GB"


def format_runtime(seconds: float | None) -> str:
    """Render seconds as zero-padded ``DDd:HHh:MMm:SSs``."""
    if seconds is None:
        return ""
    total = int(round(seconds))
    days, rem = divmod(total, 86400)
    hours, rem = divmod(rem, 3600)
    minutes, secs = divmod(rem, 60)
    return f"{days:02d}d:{hours:02d}h:{minutes:02d}m:{secs:02d}s"


# --------------------------------------------------------------------------- #
# S1: flow_inputs/config.log (ASCII box-drawing table) parsing
# --------------------------------------------------------------------------- #
def parse_config_table(text: str) -> dict[str, str]:
    """Parse a pprtl ``flow_inputs/config.log`` table into ``{Config: Value}``.

    Format::

        +-------+-------+--------+
        | Config | Value | Source |
        +-------+-------+--------+
        | DUT    | imh   | Env... |

    Duplicate keys (e.g. ``SDC_FILE`` can appear twice) keep the *first*
    occurrence.
    """
    values: dict[str, str] = {}
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        parts = line.split("|")
        if len(parts) < 4:
            continue
        key = parts[1].strip()
        value = parts[2].strip()
        if not key or key == "Config" or set(key) <= {"-"}:
            continue
        if key not in values:
            values[key] = value
    return values


def parse_config_log(path: Path) -> dict[str, str]:
    text = _read(path)
    return parse_config_table(text) if text is not None else {}


# --------------------------------------------------------------------------- #
# Generic report-file parsers
# --------------------------------------------------------------------------- #
def parse_keyvalue_report(text: str) -> dict[str, str]:
    """Parse ``Key: value`` / ``Key : value`` lines into a dict (first wins).

    Used for ``*.stat2.rpt`` (timebased mode's annotation fields).
    """
    out: dict[str, str] = {}
    for line in text.splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if key and key not in out:
            out[key] = value
    return out


_RTL_METRICS_COLUMNS = {
    "cell_count": "All Cell Count",
    "combinational_cell_count": "Combinational Cell Count",
    "unclocked_sequential_cell_count": "Sequential Cell Count",
    "register_cell_count": "Register Cell Count",
    "register_bit_count": "Register Bit Count",
    "CGR": "CGR (%)",
    "CGE": "CGE (%)",
    "DACGE": "DACGE (%)",
    "flop_cell_count": "Flop Cell Count",
    "mbflop_cell_count": "MBFlop Cell Count",
    "eqfb": "EQFB",
    "latch_cell_count": "Latch Cell Count",
    "mblatch_cell_count": "MBLatch Cell Count",
    "eqlb": "EQLB",
}
_RTL_METRICS_FLOAT_FIELDS = {"CGR", "CGE", "DACGE"}


def parse_rtl_metrics_hier_csv(path: Path, module: str) -> dict | None:
    """Find the module's own top-of-hierarchy row in a ``*.rtl_metrics.hier.csv``
    (S25) and stop reading immediately once found.

    This file can have 10000+ hierarchy rows, but the module's own row is
    always the top-level one, identified by ``Hierarchy Level`` == "0" (it is
    also always the first data row on real data, but matching on Hierarchy
    Level rather than position is more robust). Breaking out of the loop as
    soon as it's found avoids reading/parsing the rest of a huge file.
    """
    try:
        with path.open(newline="", encoding="utf-8", errors="replace") as fh:
            reader = csv.DictReader(fh)
            for row in reader:
                if row.get("Hierarchy Level", "").strip() != "0":
                    continue
                if row.get("Module Name", "").strip() != module:
                    continue
                out: dict = {}
                for key, column in _RTL_METRICS_COLUMNS.items():
                    raw = row.get(column)
                    if raw is None or not raw.strip():
                        continue
                    out[key] = _to_float(raw) if key in _RTL_METRICS_FLOAT_FIELDS else _to_int(raw)
                return out
    except OSError:
        return None
    return None


# --------------------------------------------------------------------------- #
# S2: netbatch (grdlbuild) footer + flow.log footer parsing
# --------------------------------------------------------------------------- #
_EXIT_RE = re.compile(r"Exit Status\s*:\s*(-?\d+)")
_WC_RE = re.compile(r"WC\s+(?:(?P<d>\d+)d:)?(?P<h>\d+)h:(?P<m>\d+)m:(?P<s>\d+)s")
_MEM_RE = re.compile(r"Mem\s*:\s*(\d+)")


def parse_grdlbuild_footer(text: str) -> dict:
    """Parse the netbatch footer block written by grdlbuild's ``power.*.log``."""
    out: dict = {}
    m = _EXIT_RE.search(text)
    if m:
        out["exit_code"] = int(m.group(1))
    m = _WC_RE.search(text)
    if m:
        days = int(m.group("d") or 0)
        hours, minutes, seconds = int(m.group("h")), int(m.group("m")), int(m.group("s"))
        out["runtime_seconds"] = float(days * 86400 + hours * 3600 + minutes * 60 + seconds)
    m = _MEM_RE.search(text)
    if m:
        out["memory_gb"] = int(m.group(1)) / 1000.0  # Rusage Mem is in MB
    return out


_FLOW_ELAPSED_RE = re.compile(r"Elapsed time for this session:\s*([\d.]+)\s*seconds")
_FLOW_MEM_RE = re.compile(r"Maximum memory usage for this session:\s*[\d,]+\s*KB\s*\(([\d.]+)\s*GB\)")


def parse_flow_log_footer(text: str) -> dict:
    out: dict = {}
    m = _FLOW_ELAPSED_RE.search(text)
    if m:
        out["runtime_seconds"] = float(m.group(1))
    m = _FLOW_MEM_RE.search(text)
    if m:
        out["memory_gb"] = float(m.group(1))
    return out


_VCS_VERSION_RE = re.compile(r"Version\s+(\S+)\s+--")
_VERDI_VERSION_RE = re.compile(r"VERDI_HOME\s*=\s*.*/verdi3/(\S+)")
_PPRTL_VERSION_RE = re.compile(r"Version:\s*(\S+)\s+for linux64")


def extract_version_info(vcs_log: Path | None, elab_grdlbuild_log: Path) -> dict:
    """Module-level tool versions -- one elab run per module regardless of
    power mode, so these are the same for every row of a module.

    VCS_VERSION comes from S6 (elab/pprtl_work/vcs/vcs.log)'s 2nd line;
    VERDI_VERSION/PPRTL_VERSION come from S2's elab activity grdlbuild log.
    """
    vcs_version = verdi_version = pprtl_version = None

    vcs_text = _read(vcs_log)
    if vcs_text is not None:
        m = _VCS_VERSION_RE.search(vcs_text)
        if m:
            vcs_version = m.group(1)
            if vcs_version.endswith("_Full64"):
                vcs_version = vcs_version[: -len("_Full64")]

    elab_text = _read(elab_grdlbuild_log)
    if elab_text is not None:
        m = _VERDI_VERSION_RE.search(elab_text)
        if m:
            verdi_version = m.group(1)
        m = _PPRTL_VERSION_RE.search(elab_text)
        if m:
            pprtl_version = m.group(1)

    return {"VCS_VERSION": vcs_version, "VERDI_VERSION": verdi_version, "PPRTL_VERSION": pprtl_version}


# --------------------------------------------------------------------------- #
# Stage status/runtime/memory evaluation
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class StageResult:
    status: str  # Pass / Fail=<n> / Running / Not Started / Not Required
    runtime_seconds: float | None
    memory_gb: float | None


def grdlbuild_log_path(workarea: Path, module: str, activity: str) -> Path:
    """activity: elab / fsdb / power_vectorless / power_timebased."""
    return workarea / "output" / "grdlbuild_power" / "logs" / f"power.{module}.pprtl2_{activity}.log"


def evaluate_stage(*, grdlbuild_log: Path, flow_log: Path | None = None) -> StageResult:
    """Determine Pass/Fail/Running/Not-Started using the grdlbuild log as sole
    ground truth (the netbatch job log at ``output/grdlbuild_power/logs/``):

    - Not Started: the grdlbuild log for the activity does not exist.
    - Running: the log exists but has no "Exit Status" netbatch footer yet.
    - Pass / Fail=<n>: the footer's Exit Status is 0 / non-zero.

    ``flow_log`` (elab/fsdb/power's own flow.log, if any) is used only to fill
    in runtime/memory when the grdlbuild footer doesn't have them -- it plays
    no part in the Pass/Fail/Running/Not-Started determination itself.
    """
    grdl_text = _read(grdlbuild_log)
    if grdl_text is None:
        return StageResult("Not Started", None, None)

    footer = parse_grdlbuild_footer(grdl_text)
    exit_code = footer.get("exit_code")
    runtime = footer.get("runtime_seconds")
    memory = footer.get("memory_gb")

    if flow_log is not None:
        flow_text = _read(flow_log)
        if flow_text is not None:
            f = parse_flow_log_footer(flow_text)
            if runtime is None:
                runtime = f.get("runtime_seconds")
            if memory is None:
                memory = f.get("memory_gb")

    if exit_code is None:
        return StageResult("Running", runtime, memory)
    if exit_code == 0:
        return StageResult("Pass", runtime, memory)
    return StageResult(f"Fail={exit_code}", runtime, memory)


# --------------------------------------------------------------------------- #
# Pass-dir discovery (S1) -- both layouts, grouped by TOP_MODULE_NAME
# --------------------------------------------------------------------------- #
@dataclass
class PassCandidate:
    module: str
    pass_dir: Path
    mtime: float
    config: dict[str, str]


def _iter_subdirs(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return [p for p in root.iterdir() if p.is_dir()]


def find_pass_candidates(workarea: Path, dut: str) -> list[PassCandidate]:
    """Enumerate every pass-dir under both known output layouts for *dut*."""
    dirs: list[Path] = list(_iter_subdirs(workarea / "output" / dut / "pprtl2"))
    partition_root = workarea / "output" / dut / "partition"
    if partition_root.is_dir():
        for module_dir in partition_root.iterdir():
            dirs += _iter_subdirs(module_dir / "pprtl2")

    candidates: list[PassCandidate] = []
    for pass_dir in dirs:
        cfg_path = pass_dir / "flow_inputs" / "config.log"
        if not cfg_path.is_file():
            continue
        cfg = parse_config_log(cfg_path)
        module = cfg.get("TOP_MODULE_NAME") or pass_dir.name
        try:
            mtime = pass_dir.stat().st_mtime
        except OSError:
            mtime = 0.0
        candidates.append(PassCandidate(module=module, pass_dir=pass_dir, mtime=mtime, config=cfg))
    return candidates


def select_newest_per_module(candidates: list[PassCandidate]) -> dict[str, PassCandidate]:
    best: dict[str, PassCandidate] = {}
    for c in candidates:
        cur = best.get(c.module)
        if cur is None or c.mtime > cur.mtime:
            best[c.module] = c
    return best


# --------------------------------------------------------------------------- #
# QoR extraction (S25 primary; S14-S18's stat2.rpt supplies annotations only)
# --------------------------------------------------------------------------- #
_ANNOTATION_PCT_RE = re.compile(r"\(([\d.]+)\s*%\)")


def _extract_annotation_pct(value: str | None) -> float | None:
    """stat2.rpt annotation fields look like ``4,075(96.75%)`` -- keep only
    the percentage number, e.g. ``96.75``."""
    if value is None:
        return None
    m = _ANNOTATION_PCT_RE.search(value)
    return _to_float(m.group(1)) if m else None


def extract_qor_fields(reports_dir: Path, module: str, mode: str, stat2_path: Path | None) -> dict:
    metrics: dict = {}
    if reports_dir is not None:
        rtl_metrics_path = reports_dir / f"{module}.rtl_metrics.hier.csv"
        if rtl_metrics_path.is_file():
            metrics = parse_rtl_metrics_hier_csv(rtl_metrics_path, module) or {}

    cell_count = metrics.get("cell_count")
    combinational_cell_count = metrics.get("combinational_cell_count")
    register_cell_count = metrics.get("register_cell_count")
    unclocked_sequential_cell_count = metrics.get("unclocked_sequential_cell_count")
    register_bit_count = metrics.get("register_bit_count")
    cgr, cge, dacge = metrics.get("CGR"), metrics.get("CGE"), metrics.get("DACGE")

    annotation_primary_io = annotation_bb = annotation_seq = None
    if mode == "timebased":
        stat2_text = _read(stat2_path)
        if stat2_text is not None:
            stat2 = parse_keyvalue_report(stat2_text)
            annotation_primary_io = _extract_annotation_pct(stat2.get("Primary I/P annotation"))
            annotation_bb = _extract_annotation_pct(stat2.get("Black Box annotation"))
            annotation_seq = _extract_annotation_pct(stat2.get("Sequential annotation"))

    untraced = None
    if register_cell_count is not None and unclocked_sequential_cell_count is not None:
        denom = register_cell_count + unclocked_sequential_cell_count
        if denom:
            untraced = round(unclocked_sequential_cell_count / denom * 100, 2)

    return {
        "cell_count": cell_count,
        "combinational_cell_count": combinational_cell_count,
        "register_cell_count": register_cell_count,
        "unclocked_sequential_cell_count": unclocked_sequential_cell_count,
        "register_bit_count": register_bit_count,
        "untraced_sequentials_percentage": untraced,
        "CGR": round(cgr, 2) if cgr is not None else None,
        "CGE": round(cge, 2) if cge is not None else None,
        "DACGE": round(dacge, 2) if dacge is not None else None,
        "flop_cell_count": metrics.get("flop_cell_count"),
        "mbflop_cell_count": metrics.get("mbflop_cell_count"),
        "eqfb": metrics.get("eqfb"),
        "latch_cell_count": metrics.get("latch_cell_count"),
        "mblatch_cell_count": metrics.get("mblatch_cell_count"),
        "eqlb": metrics.get("eqlb"),
        "annotation_primary_io": annotation_primary_io,
        "annotation_bb": annotation_bb,
        "annotation_seq": annotation_seq,
    }


# --------------------------------------------------------------------------- #
# Row model: one per (module, power_mode, test_name, instance)
# --------------------------------------------------------------------------- #
@dataclass
class Row:
    module: str
    power_mode: str  # "vectorless" or "timebased"
    test_name: str  # "default" for vectorless (build_rows()); "" for a timebased row with no test dirs yet
    instance: str  # "" for vectorless
    elab: StageResult
    fsdb: StageResult
    power: StageResult
    qor: dict = field(default_factory=dict)
    elab_flow_log: Path | None = None
    elab_grdl_log: Path | None = None
    fsdb_flow_log: Path | None = None
    fsdb_grdl_log: Path | None = None
    power_flow_log: Path | None = None
    power_grdl_log: Path | None = None
    wattson_log: Path | None = None
    vcs_log: Path | None = None
    read_sdc_log: Path | None = None


@dataclass
class ModuleStatus:
    """The 4 grdlbuild-truth activity statuses for one module (spec §3.1/§3.3).

    elab/fsdb/timebased_power are each a SINGLE grdlbuild task per module (not
    per test) -- fsdb/timebased_power are None when the module isn't a
    timebased target; vectorless_power is None when it isn't a vectorless
    target.
    """

    elab: StageResult
    vectorless_power: StageResult | None
    fsdb: StageResult | None
    timebased_power: StageResult | None


def read_partition_list(path: Path) -> list[str]:
    """Parse a bare-module-name-per-line partition list (S20/S20b)."""
    text = _read(path)
    if text is None:
        return []
    return [ln.strip() for ln in text.splitlines() if ln.strip() and not ln.strip().startswith("#")]


def build_rows(
    cfg: Config,
) -> tuple[list[Row], dict[str, PassCandidate], dict[str, ModuleStatus]]:
    candidates = find_pass_candidates(cfg.workarea, cfg.dut)
    chosen = select_newest_per_module(candidates)

    # Every partition in S20 (prep_pprtl2_partition.list) is a vectorless+elab
    # target; S20b (prep_pprtl2_timebased_partition.list) is the timebased-
    # eligible subset. When either list is unavailable (e.g. an ad-hoc
    # single-module workarea with no prep_pprtl2 run), fall back to whatever
    # was actually discovered on disk for that specific mode.
    vectorless_targets = set(read_partition_list(cfg.partition_list))
    timebased_targets = set(read_partition_list(cfg.timebased_partition_list))
    for module, cand in chosen.items():
        if (cand.pass_dir / "power" / "vectorless").is_dir():
            vectorless_targets.add(module)
        if (cand.pass_dir / "power" / "timebased").is_dir():
            timebased_targets.add(module)

    rows: list[Row] = []
    module_status: dict[str, ModuleStatus] = {}

    for module in sorted(vectorless_targets | timebased_targets):
        cand = chosen.get(module)
        pass_dir = cand.pass_dir if cand else None

        elab_grdl = grdlbuild_log_path(cfg.workarea, module, "elab")
        elab_flow_log = (pass_dir / "elab" / "log" / "flow.log") if pass_dir else None
        elab_result = evaluate_stage(grdlbuild_log=elab_grdl, flow_log=elab_flow_log)

        wattson_log = (pass_dir / "elab" / "pprtl_work" / "wattson.log") if pass_dir else None
        vcs_log = (pass_dir / "elab" / "pprtl_work" / "vcs" / "vcs.log") if pass_dir else None
        read_sdc_log = (pass_dir / "elab" / "pprtl_work" / "sdc" / "read_sdc.log") if pass_dir else None
        # Tool versions are module-level (one elab run per module) -- computed
        # once and merged into every row's qor dict below.
        version_info = extract_version_info(vcs_log, elab_grdl)

        vectorless_power_result = fsdb_result = timebased_power_result = None

        if module in vectorless_targets:
            power_grdl = grdlbuild_log_path(cfg.workarea, module, "power_vectorless")
            power_flow_log = (
                pass_dir / "power" / "vectorless" / "default" / "log" / "vectorless.flow.log"
                if pass_dir else None
            )
            vectorless_power_result = evaluate_stage(grdlbuild_log=power_grdl, flow_log=power_flow_log)
            reports_dir = (pass_dir / "power" / "vectorless" / "default" / "reports") if pass_dir else None
            qor = extract_qor_fields(reports_dir, module, "vectorless", None) if reports_dir else {}
            qor = {**qor, **version_info}
            rows.append(Row(
                module=module, power_mode="vectorless", test_name="default", instance="",
                elab=elab_result, fsdb=StageResult("Not Required", None, None),
                power=vectorless_power_result, qor=qor,
                elab_flow_log=elab_flow_log, elab_grdl_log=elab_grdl,
                power_flow_log=power_flow_log, power_grdl_log=power_grdl,
                wattson_log=wattson_log, vcs_log=vcs_log, read_sdc_log=read_sdc_log,
            ))

        if module in timebased_targets:
            # fsdb and timebased power are each ONE grdlbuild task per module,
            # covering every test in one job -- compute once, share across rows.
            fsdb_grdl = grdlbuild_log_path(cfg.workarea, module, "fsdb")
            power_grdl = grdlbuild_log_path(cfg.workarea, module, "power_timebased")
            fsdb_result = evaluate_stage(grdlbuild_log=fsdb_grdl, flow_log=None)
            timebased_power_result = evaluate_stage(grdlbuild_log=power_grdl, flow_log=None)

            timebased_dir = (pass_dir / "power" / "timebased") if pass_dir else None
            test_instances = []
            if timebased_dir is not None and timebased_dir.is_dir():
                for test_dir in sorted(_iter_subdirs(timebased_dir)):
                    for inst_dir in sorted(_iter_subdirs(test_dir)):
                        test_instances.append((test_dir.name, inst_dir.name, inst_dir))

            if not test_instances:
                rows.append(Row(
                    module=module, power_mode="timebased", test_name="", instance="",
                    elab=elab_result, fsdb=fsdb_result, power=timebased_power_result, qor=dict(version_info),
                    elab_flow_log=elab_flow_log, elab_grdl_log=elab_grdl,
                    fsdb_grdl_log=fsdb_grdl, power_grdl_log=power_grdl,
                    wattson_log=wattson_log, vcs_log=vcs_log, read_sdc_log=read_sdc_log,
                ))
            else:
                for test_name, instance, inst_dir in test_instances:
                    fsdb_flow_log = pass_dir / "fsdb" / test_name / instance / "log" / "flow.log"
                    power_flow_log = inst_dir / "log" / "timebased.flow.log"
                    reports_dir = inst_dir / "reports"
                    stat2_path = reports_dir / f"{module}.stat2.rpt"
                    qor = {**extract_qor_fields(reports_dir, module, "timebased", stat2_path), **version_info}
                    rows.append(Row(
                        module=module, power_mode="timebased", test_name=test_name, instance=instance,
                        elab=elab_result, fsdb=fsdb_result, power=timebased_power_result, qor=qor,
                        elab_flow_log=elab_flow_log, elab_grdl_log=elab_grdl,
                        fsdb_flow_log=fsdb_flow_log, fsdb_grdl_log=fsdb_grdl,
                        power_flow_log=power_flow_log, power_grdl_log=power_grdl,
                        wattson_log=wattson_log, vcs_log=vcs_log, read_sdc_log=read_sdc_log,
                    ))

        module_status[module] = ModuleStatus(
            elab=elab_result, vectorless_power=vectorless_power_result,
            fsdb=fsdb_result, timebased_power=timebased_power_result,
        )

    return rows, chosen, module_status


# --------------------------------------------------------------------------- #
# report_pprtl2.compute.csv
# --------------------------------------------------------------------------- #
_COMPUTE_FIELDS = [
    "module", "power_mode", "test_name", "instance",
    "elab_run_status", "fsdb_run_status", "power_run_status", "cell_count",
    "elab_runtime", "elab_runtime_seconds",
    "fsdb_runtime", "fsdb_runtime_seconds",
    "power_runtime", "power_runtime_seconds",
    "total_runtime", "total_runtime_seconds",
    "elab_peak_memory", "fsdb_peak_memory", "power_peak_memory",
]


def write_compute_csv(cfg: Config, rows: list[Row]) -> None:
    with cfg.compute_csv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=_COMPUTE_FIELDS)
        writer.writeheader()
        for r in rows:
            elab_s, fsdb_s, power_s = r.elab.runtime_seconds, r.fsdb.runtime_seconds, r.power.runtime_seconds
            total_s = sum(s for s in (elab_s, fsdb_s, power_s) if s is not None)
            writer.writerow({
                "module": r.module,
                "power_mode": r.power_mode,
                "test_name": r.test_name,
                "instance": r.instance,
                "elab_run_status": r.elab.status,
                "fsdb_run_status": r.fsdb.status,
                "power_run_status": r.power.status,
                "cell_count": _blank(r.qor.get("cell_count")),
                "elab_runtime": format_runtime(elab_s),
                "elab_runtime_seconds": _blank(elab_s),
                "fsdb_runtime": format_runtime(fsdb_s),
                "fsdb_runtime_seconds": _blank(fsdb_s),
                "power_runtime": format_runtime(power_s),
                "power_runtime_seconds": _blank(power_s),
                "total_runtime": format_runtime(total_s),
                "total_runtime_seconds": _blank(total_s),
                "elab_peak_memory": fmt_mem(r.elab.memory_gb),
                "fsdb_peak_memory": fmt_mem(r.fsdb.memory_gb),
                "power_peak_memory": fmt_mem(r.power.memory_gb),
            })


# --------------------------------------------------------------------------- #
# report_pprtl2.qor.csv
# --------------------------------------------------------------------------- #
_QOR_FIELDS = [
    "module", "power_mode", "test_name", "instance",
    "elab_run_status", "fsdb_run_status", "power_run_status",
    "untraced_sequentials_percentage", "annotation_primary_io", "annotation_bb", "annotation_seq",
    "CGR", "CGE", "DACGE",
    "cell_count", "combinational_cell_count", "unclocked_sequential_cell_count",
    "register_cell_count", "register_bit_count",
    "flop_cell_count", "mbflop_cell_count", "eqfb",
    "latch_cell_count", "mblatch_cell_count", "eqlb",
    "VCS_VERSION", "VERDI_VERSION", "PPRTL_VERSION",
]


def write_qor_csv(cfg: Config, rows: list[Row]) -> None:
    with cfg.qor_csv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=_QOR_FIELDS)
        writer.writeheader()
        for r in rows:
            q = r.qor
            writer.writerow({
                "module": r.module,
                "power_mode": r.power_mode,
                "test_name": r.test_name,
                "instance": r.instance,
                "elab_run_status": r.elab.status,
                "fsdb_run_status": r.fsdb.status,
                "power_run_status": r.power.status,
                "untraced_sequentials_percentage": _blank(q.get("untraced_sequentials_percentage")),
                "annotation_primary_io": _blank(q.get("annotation_primary_io")),
                "annotation_bb": _blank(q.get("annotation_bb")),
                "annotation_seq": _blank(q.get("annotation_seq")),
                "CGR": _blank(q.get("CGR")),
                "CGE": _blank(q.get("CGE")),
                "DACGE": _blank(q.get("DACGE")),
                "cell_count": _blank(q.get("cell_count")),
                "combinational_cell_count": _blank(q.get("combinational_cell_count")),
                "unclocked_sequential_cell_count": _blank(q.get("unclocked_sequential_cell_count")),
                "register_cell_count": _blank(q.get("register_cell_count")),
                "register_bit_count": _blank(q.get("register_bit_count")),
                "flop_cell_count": _blank(q.get("flop_cell_count")),
                "mbflop_cell_count": _blank(q.get("mbflop_cell_count")),
                "eqfb": _blank(q.get("eqfb")),
                "latch_cell_count": _blank(q.get("latch_cell_count")),
                "mblatch_cell_count": _blank(q.get("mblatch_cell_count")),
                "eqlb": _blank(q.get("eqlb")),
                "VCS_VERSION": _blank(q.get("VCS_VERSION")),
                "VERDI_VERSION": _blank(q.get("VERDI_VERSION")),
                "PPRTL_VERSION": _blank(q.get("PPRTL_VERSION")),
            })


# --------------------------------------------------------------------------- #
# report_pprtl2.summary
# --------------------------------------------------------------------------- #
_TOTAL_RE = re.compile(r"^total partitions\s*:\s*(\d+)", re.MULTILINE)


def symlink_target(path: Path) -> str:
    """Resolve REF_MODEL/SDC_ARCHIVE/MTL_FILE to the real path their symlink
    points at."""
    if not path.exists():
        return "NA"
    try:
        return str(path.resolve())
    except OSError:
        return "NA"


def _has_grdlbuild_log(workarea: Path, module: str) -> bool:
    """True if any of the module's grdlbuild netbatch logs exist (complete or
    partial coverage both count)."""
    return any(
        grdlbuild_log_path(workarea, module, activity).is_file()
        for activity in ("elab", "fsdb", "power_vectorless", "power_timebased")
    )


def _has_stage_flow_log(rows_for_module: list[Row]) -> bool:
    """True if any stage's flow.log file exists on disk for this module's rows."""
    for r in rows_for_module:
        for p in (r.elab_flow_log, r.fsdb_flow_log, r.power_flow_log):
            if p is not None and p.is_file():
                return True
    return False


def _tally(results: list[StageResult]) -> tuple[int, int, int, int]:
    """(pass, fail, running, not_started) counts for a list of StageResults."""
    p = f = r = n = 0
    for result in results:
        if result.status == "Pass":
            p += 1
        elif result.status.startswith("Fail"):
            f += 1
        elif result.status == "Running":
            r += 1
        elif result.status == "Not Started":
            n += 1
    return p, f, r, n


def _status_block(label: str, results: list[StageResult]) -> list[str]:
    denom = len(results)
    p, f, r, n = _tally(results)

    def pct(numer: int) -> float:
        return round(numer / denom * 100, 1) if denom else 0.0

    return [
        f"total partitions pass {label}: {p}  {pct(p)}%",
        f"total partitions fail {label}:  {f}  {pct(f)}%",
        f"total partitions still running {label}:  {r}  {pct(r)}%",
        f"total partitions not started {label}:  {n}  {pct(n)}%",
    ]


def _activity_action_lists(
    module_status: dict[str, ModuleStatus], attr: str,
) -> tuple[list[str], list[str], list[str]]:
    """(fail, running, not_started) module names for one activity, sorted."""
    fail: list[str] = []
    running: list[str] = []
    not_started: list[str] = []
    for module in sorted(module_status):
        result = getattr(module_status[module], attr)
        if result is None:
            continue
        if result.status.startswith("Fail"):
            fail.append(module)
        elif result.status == "Running":
            running.append(module)
        elif result.status == "Not Started":
            not_started.append(module)
    return fail, running, not_started


def _action_section(
    cfg: Config, label: str, activity: str,
    fail: list[str], running: list[str], not_started: list[str],
) -> list[str]:
    """Lists of partitions needing action for one activity (spec §3.3)."""
    lines = [f"Partitions that fail {label}:"]
    if fail:
        lines += [f"{m}  {grdlbuild_log_path(cfg.workarea, m, activity)}" for m in fail]
    else:
        lines.append(f"No partitions failed {label}")

    lines += ["", f"Partitions that are still running {label}:"]
    if running:
        lines += [f"{m}  {grdlbuild_log_path(cfg.workarea, m, activity)}" for m in running]
    else:
        lines.append(f"No partitions are still running {label}")

    lines += ["", f"Partitions that have not started {label}:"]
    if not_started:
        lines += not_started
    else:
        lines.append(f"No partitions have not started {label}")

    return lines


def _row_total_runtime_seconds(r: Row) -> float:
    """Sum of elab/fsdb/power runtime_seconds, treating missing stages as 0
    (matches compute.csv's total_runtime_seconds column)."""
    return sum(
        s for s in (r.elab.runtime_seconds, r.fsdb.runtime_seconds, r.power.runtime_seconds) if s is not None
    )


def _runtime_stats_section(rows: list[Row], power_mode: str, label: str) -> list[str]:
    """Runtime count/mean/fastest-5/slowest-5 for partitions whose <label>
    power run passed (spec §3.3) -- one entry per module (dedup, since
    timebased fsdb/power runtime is shared across every test row of a module).
    """
    by_module: dict[str, Row] = {}
    for r in rows:
        if r.power_mode == power_mode and r.power.status == "Pass" and r.module not in by_module:
            by_module[r.module] = r

    if not by_module:
        return [f"No runtime datapoints for {label} power (no passing runs)"]

    entries = sorted((_row_total_runtime_seconds(r), m) for m, r in by_module.items())
    mean_seconds = sum(secs for secs, _ in entries) / len(entries)

    lines = [
        f"number of partitions passing {label} power: {len(entries)}",
        f"mean total runtime all partitions passing {label} power: {format_runtime(mean_seconds)}",
        "",
        f"Top 5 fastest partitions with passing {label} power runs:",
    ]
    lines += [f"{format_runtime(secs)}  {m}" for secs, m in entries[:5]]
    lines += ["", f"Bottom 5 slowest partitions with passing {label} power runs:"]
    lines += [f"{format_runtime(secs)}  {m}" for secs, m in entries[-5:]]
    return lines


def render_summary_md(
    cfg: Config,
    rows: list[Row],
    chosen: dict[str, PassCandidate],
    module_status: dict[str, ModuleStatus],
    command_line: str = "",
) -> str:
    def pct(numer: int, denom: int) -> float:
        return round(numer / denom * 100, 1) if denom else 0.0

    prep_summary_text = _read(cfg.report_summary) or ""
    total_m = _TOTAL_RE.search(prep_summary_text)
    total_partitions = int(total_m.group(1)) if total_m else len(chosen)

    rows_by_module: dict[str, list[Row]] = {}
    for r in rows:
        rows_by_module.setdefault(r.module, []).append(r)
    all_modules = sorted(rows_by_module)
    grdlbuild_count = sum(1 for m in all_modules if _has_grdlbuild_log(cfg.workarea, m))
    flow_log_count = sum(1 for m in all_modules if _has_stage_flow_log(rows_by_module[m]))

    elab_results = [m.elab for m in module_status.values()]
    vectorless_results = [m.vectorless_power for m in module_status.values() if m.vectorless_power is not None]
    fsdb_results = [m.fsdb for m in module_status.values() if m.fsdb is not None]
    timebased_power_results = [
        m.timebased_power for m in module_status.values() if m.timebased_power is not None
    ]

    tb_rows = [r for r in rows if r.power_mode == "timebased"]
    multi_test_modules = sorted(
        m for m in {r.module for r in tb_rows}
        if len({r.test_name for r in tb_rows if r.module == m}) > 1
    )

    lines = [
        f"Command Line: {command_line}",
        f"Workarea: {cfg.workarea}",
        f"REF_MODEL: {symlink_target(cfg.ref_model)}",
        f"SDC_ARCHIVE: {symlink_target(cfg.sdc_archive)}",
        f"MTL_FILE: {symlink_target(cfg.mtl_file)}",
        f"DUT: {cfg.dut}",
        f"total partitions {total_partitions}",
    ]
    lines.append(
        f"total partitions with at least one grdlbuild log: {grdlbuild_count}  "
        f"{pct(grdlbuild_count, total_partitions)}%"
    )
    lines.append(
        f"total partitions with at least one stage flow.log file: {flow_log_count}  "
        f"{pct(flow_log_count, total_partitions)}%"
    )

    elab_fail, elab_running, elab_not_started = _activity_action_lists(module_status, "elab")
    vec_fail, vec_running, vec_not_started = _activity_action_lists(module_status, "vectorless_power")
    fsdb_fail, fsdb_running, fsdb_not_started = _activity_action_lists(module_status, "fsdb")
    tbp_fail, tbp_running, tbp_not_started = _activity_action_lists(module_status, "timebased_power")

    lines += ["", "elab:"]
    lines += _status_block("elab", elab_results)

    lines += ["", "vectorless:"]
    lines += _status_block("vectorless power", vectorless_results)

    lines += ["", "timebased:"]
    lines += _status_block("fsdb", fsdb_results)
    lines += ["", *_status_block("timebased power", timebased_power_results)]

    lines += ["", "Action Required:"]
    lines += ["", *_action_section(cfg, "elab", "elab", elab_fail, elab_running, elab_not_started)]
    lines += [
        "", *_action_section(cfg, "vectorless power", "power_vectorless", vec_fail, vec_running, vec_not_started),
    ]
    lines += ["", *_action_section(cfg, "fsdb", "fsdb", fsdb_fail, fsdb_running, fsdb_not_started)]
    lines += [
        "",
        *_action_section(cfg, "timebased power", "power_timebased", tbp_fail, tbp_running, tbp_not_started),
    ]

    lines += ["", *_runtime_stats_section(rows, "timebased", "timebased")]
    lines += ["", *_runtime_stats_section(rows, "vectorless", "vectorless")]

    lines += [
        "",
        f"total partitions that executed greater than one testname: {len(multi_test_modules)}",
        "",
        "Partitions that executed greater than one test in timebased run:",
    ]
    if multi_test_modules:
        lines += multi_test_modules
    else:
        lines.append("No Partitions Executed Greater Than One Test")
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- #
# report_pprtl2.fail.details
# --------------------------------------------------------------------------- #
_GREP_PATTERN = re.compile(r"(Error:)|(Error\-)|(\[ERROR\])")
_GREP_LINES_BEFORE = 1
_GREP_LINES_AFTER = 3


def grep_context_blocks(text: str) -> list[str]:
    """Grep _GREP_PATTERN, returning a window of 1 line before/3 lines after
    each match. Overlapping/adjacent windows are merged; separate windows are
    joined with an ``...`` separator."""
    lines = text.splitlines()
    match_indices = [i for i, ln in enumerate(lines) if _GREP_PATTERN.search(ln)]
    if not match_indices:
        return []

    windows: list[list[int]] = []
    for i in match_indices:
        start = max(0, i - _GREP_LINES_BEFORE)
        end = min(len(lines) - 1, i + _GREP_LINES_AFTER)
        if windows and start <= windows[-1][1] + 1:
            windows[-1][1] = max(windows[-1][1], end)
        else:
            windows.append([start, end])

    out: list[str] = []
    for idx, (start, end) in enumerate(windows):
        if idx > 0:
            out.append("...")
        out.extend(lines[start:end + 1])
    return out


def _log_block(path: Path | None) -> list[str]:
    lines = [f"Log: {path if path is not None else 'N/A'}"]
    if path is None or not path.is_file():
        lines.append("No matches found")
        lines.append("")
        return lines
    text = _read(path) or ""
    blocks = grep_context_blocks(text)
    lines.extend(blocks if blocks else ["No matches found"])
    lines.append("")
    return lines


def render_fail_details(rows: list[Row]) -> str:
    lines: list[str] = []

    by_module: dict[str, list[Row]] = {}
    for r in rows:
        by_module.setdefault(r.module, []).append(r)

    for module in sorted(by_module):
        module_rows = by_module[module]

        def is_fail(r: Row) -> bool:
            return (
                r.elab.status.startswith("Fail")
                or r.fsdb.status.startswith("Fail")
                or r.power.status.startswith("Fail")
            )

        if not any(is_fail(r) for r in module_rows):
            continue

        first = module_rows[0]
        failing_tests = sorted(
            {r.test_name for r in module_rows if r.test_name and (r.fsdb.status.startswith("Fail") or r.power.status.startswith("Fail"))}
        )

        reasons = []
        if first.elab.status.startswith("Fail"):
            reasons.append(f"elab {first.elab.status}")
        for r in module_rows:
            label = r.test_name or "default"
            if r.fsdb.status.startswith("Fail"):
                reasons.append(f"fsdb {r.fsdb.status} ({label})")
            if r.power.status.startswith("Fail"):
                reasons.append(f"power {r.power.status} ({label})")

        lines.append(f"Partition: {module}")
        lines.append(f"Test: {', '.join(failing_tests) if failing_tests else 'N/A'}")
        lines.append(f"Failure reason: {'; '.join(reasons) if reasons else 'Unknown'}")
        lines.append("Grep results:")
        lines.extend(_log_block(first.elab_grdl_log))
        lines.extend(_log_block(first.elab_flow_log))
        lines.extend(_log_block(first.wattson_log))
        lines.extend(_log_block(first.vcs_log))
        lines.extend(_log_block(first.read_sdc_log))

        for r in module_rows:
            if r.power_mode == "vectorless":
                lines.extend(_log_block(r.power_grdl_log))
                lines.extend(_log_block(r.power_flow_log))
            else:
                lines.extend(_log_block(r.fsdb_grdl_log))
                lines.extend(_log_block(r.fsdb_flow_log))
                lines.extend(_log_block(r.power_grdl_log))
                lines.extend(_log_block(r.power_flow_log))
        lines.append("")

    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- #
# report_pprtl2.README (static content, direct write, spec section 3.7)
# --------------------------------------------------------------------------- #
README_MD = """\
# report_pprtl2.README

## pprtl1 vs pprtl2 terminology

| Metric | PPRTL1 | PPRTL2 | Notes |
|---|---|---|---|
| % clock gated registers (static) | Static Clock Gating Efficiency (SCGE) | Clock Gating Ratio (CGR) | Static CGE is your upper bounds |
| % gated clock cycles; lacks correlation with data activity | Dynamic Clock Gating Efficiency (DCGE) | Clock Gating Efficiency (CGE) | |
| CGE +  [data toggle cycles / root clock cycles] | Data Aware Clock Gating Efficiency (DACGE) | Data Aware Clock Gating Efficiency (DACGE) | DACGE will be the same or higher than CGE/DCGE by nature of the arithmetic. |
| % untraced sequentials | - | Untraced Sequentials (%) | Calculated manually in pprtl1 |
| Sequential Cell Count | sequential_cell_count from get_cells -filter "is_sequential==true" | sequential+register power group | Slightly different calculation method since some sequentials can sit in clock network |


## Report fields
- To see all attributes available in the RTL metrics, use the following in the pprtl2 shell:
  `report_rtl_metrics -list_attributes -view`
- EQFB: Total count of equivalent flop cells in the listed hierarchy
- EQLB: Total count of equivalent latch cells in the listed hierarchy
- EQFB+EQLB should be very close to register_bit_count
"""


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="report_pprtl2.py",
        description="Generate pprtl2 run-area summary/QoR/compute reports.",
    )
    parser.add_argument("--dut", required=True, help="DUT directory name under output/ (e.g. imh).")
    parser.add_argument("--workarea", type=Path, default=None, help="Work area root (default: $WORKAREA).")
    parser.add_argument("--dry-run", action="store_true", help="Print the plan; write nothing.")
    parser.add_argument(
        "--force", action="store_true",
        help="No-op: reports are always regenerated/overwritten each run. Kept for CLI parity.",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose logging.")
    return parser


def resolve_config(args: argparse.Namespace) -> Config:
    workarea = args.workarea or (Path(os.environ["WORKAREA"]) if "WORKAREA" in os.environ else None)
    if workarea is None:
        raise SystemExit("-E- --workarea not given and $WORKAREA is not set.")
    return Config(dut=args.dut, workarea=workarea.resolve())


def preflight(cfg: Config) -> list[str]:
    errors = []
    if not cfg.workarea.is_dir():
        errors.append(f"workarea not found: {cfg.workarea}")
        return errors
    flat = cfg.workarea / "output" / cfg.dut / "pprtl2"
    partitioned = cfg.workarea / "output" / cfg.dut / "partition"
    if not flat.is_dir() and not partitioned.is_dir():
        errors.append(f"no power output run area found under {flat} or {partitioned}")
    if not cfg.out_root.is_dir():
        errors.append(f"{cfg.out_root} does not exist")
    return errors


def _command_line(argv: list[str] | None) -> str:
    if argv is None:
        return " ".join(sys.argv)
    return " ".join(["report_pprtl2.py", *argv])


def generate_reports(
    cfg: Config, command_line: str = "",
) -> tuple[list[Row], dict[str, PassCandidate], dict[str, ModuleStatus]]:
    rows, chosen, module_status = build_rows(cfg)
    write_compute_csv(cfg, rows)
    write_qor_csv(cfg, rows)
    cfg.summary.write_text(
        render_summary_md(cfg, rows, chosen, module_status, command_line), encoding="utf-8",
    )
    cfg.fail_details.write_text(render_fail_details(rows), encoding="utf-8")
    cfg.readme.write_text(README_MD, encoding="utf-8")
    return rows, chosen, module_status


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)
    cfg = resolve_config(args)

    errors = preflight(cfg)
    if errors:
        for e in errors:
            print(f"-E- {e}", file=sys.stderr)
        return 2

    rows, chosen, module_status = build_rows(cfg)
    if not rows:
        print("-E- No power run areas discovered.", file=sys.stderr)
        return 2

    if args.dry_run:
        print("Would write:")
        for p in (cfg.summary, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.readme):
            print(f"  {p}")
        print(f"Discovered {len(chosen)} module(s), {len(rows)} row(s).")
        return 0

    # Reuse the already-built rows/chosen (avoid re-scanning the whole run area).
    write_compute_csv(cfg, rows)
    write_qor_csv(cfg, rows)
    cfg.summary.write_text(
        render_summary_md(cfg, rows, chosen, module_status, _command_line(argv)), encoding="utf-8",
    )
    cfg.fail_details.write_text(render_fail_details(rows), encoding="utf-8")
    cfg.readme.write_text(README_MD, encoding="utf-8")

    if args.verbose:
        for p in (cfg.summary, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.readme):
            print(f"wrote {p}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
