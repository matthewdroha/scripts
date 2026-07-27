#!/usr/bin/env python3
"""report_pprtl2 — pprtl2 run-area summary/report generator.

Scans a pprtl2 (RTL power analysis) run area under ``$WORKAREA/output/<dut>/``
and produces machine- and human-readable rollup reports under
``$WORKAREA/power/pprtl2/``.

See scripts/pprtl2/report_pprtl2.spec.md for the full specification, and
scripts/pprtl2/report_pprtl2.py's companion test file for fixture-driven unit
tests of every pure-parsing function.

Deviations from the spec text, verified against real workareas on disk
(2026-07-25, see /memories/repo/report_pprtl2.md):
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
    def summary_md(self) -> Path:
        return self.out_root / "report_pprtl2.summary.md"

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
    def terminology_md(self) -> Path:
        return self.out_root / "report_pprtl2.terminology.md"

    @property
    def ref_model(self) -> Path:
        return self.out_root / "REF_MODEL"

    @property
    def sdc_archive(self) -> Path:
        return self.out_root / "SDC_ARCHIVE"

    @property
    def report_summary(self) -> Path:
        return self.out_root / "prep_pprtl2_report.summary"

    @property
    def partition_list(self) -> Path:
        return self.out_root / "prep_pprtl2_partition.list"


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

    Used for ``*.cells.rpt`` (vectorless) and ``*.stat2.rpt`` (timebased).
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


_POWER_GROUP_NAMES = {
    "clock_network", "register", "combinational", "sequential",
    "memory", "io_pad", "black_box",
}


def parse_power_groups(text: str) -> dict[str, int]:
    """Parse a ``*.power_groups.rpt`` table into ``{group_name: size}``."""
    out: dict[str, int] = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[0] in _POWER_GROUP_NAMES:
            size = _to_int(parts[1])
            if size is not None:
                out[parts[0]] = size
    return out


def parse_cge_hier_module_row(text: str, module: str) -> dict | None:
    """Find the top-level (bare module name) row in a ``*.cge.hier.rpt``.

    Columns: Register Bit Count | Gated Register Bit Count | CGR (%) |
    CGE (%) | DACGE (%) | Name.
    """
    for line in text.splitlines():
        parts = line.split()
        if len(parts) != 6:
            continue
        reg_bits = _to_int(parts[0])
        cgr = _to_float(parts[2])
        cge = _to_float(parts[3])
        dacge = _to_float(parts[4])
        if reg_bits is None or cgr is None or cge is None or dacge is None:
            continue
        if parts[5] == module:
            return {
                "register_bit_count": reg_bits,
                "CGR": cgr,
                "CGE": cge,
                "DACGE": dacge,
            }
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
_STAGE_PASSED_RE = re.compile(r"stage passed successfully", re.IGNORECASE)
_STAGE_FAILED_RE = re.compile(r"stage failed", re.IGNORECASE)


def parse_flow_log_footer(text: str) -> dict:
    out: dict = {}
    m = _FLOW_ELAPSED_RE.search(text)
    if m:
        out["runtime_seconds"] = float(m.group(1))
    m = _FLOW_MEM_RE.search(text)
    if m:
        out["memory_gb"] = float(m.group(1))
    return out


# --------------------------------------------------------------------------- #
# Stage status/runtime/memory evaluation
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class StageResult:
    status: str  # Pass / Fail / Fail=<n> / Running / Not Ran / Not Required
    runtime_seconds: float | None
    memory_gb: float | None


def grdlbuild_log_path(workarea: Path, module: str, stage: str) -> Path:
    return workarea / "output" / "grdlbuild_power" / "logs" / f"power.{module}.pprtl2_{stage}.log"


def evaluate_stage(
    *,
    pass_marker: Path,
    flow_log: Path,
    grdlbuild_log: Path | None,
) -> StageResult:
    """Determine Pass/Fail/Running/Not-Ran + runtime/memory for one stage.

    NB: there is no "Skipped" status -- a stage that never ran (whether because
    it was intentionally skipped or a dependency failed) is reported as
    "Not Ran"; disambiguating *why* is left for a future iteration.
    """
    grdl_text = _read(grdlbuild_log) if grdlbuild_log else None
    flow_text = _read(flow_log)

    runtime = memory = exit_code = None
    if grdl_text is not None:
        g = parse_grdlbuild_footer(grdl_text)
        exit_code = g.get("exit_code")
        runtime = g.get("runtime_seconds")
        memory = g.get("memory_gb")
    if flow_text is not None:
        f = parse_flow_log_footer(flow_text)
        if runtime is None:
            runtime = f.get("runtime_seconds")
        if memory is None:
            memory = f.get("memory_gb")

    if pass_marker.is_file():
        return StageResult("Pass", runtime, memory)

    if flow_text is not None and _STAGE_FAILED_RE.search(flow_text):
        return StageResult(f"Fail={exit_code}" if exit_code else "Fail", runtime, memory)

    if exit_code is not None and exit_code != 0:
        return StageResult(f"Fail={exit_code}", runtime, memory)

    if flow_text is not None and not _FLOW_ELAPSED_RE.search(flow_text):
        return StageResult("Running", runtime, memory)

    if flow_text is not None or grdl_text is not None:
        # A log exists and the stage ran to completion, but there's no .PASS
        # marker and no positive "passed successfully" evidence either.
        return StageResult(f"Fail={exit_code}" if exit_code else "Fail", runtime, memory)

    return StageResult("Not Ran", None, None)


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
# QoR extraction (S10-S18)
# --------------------------------------------------------------------------- #
def extract_qor_fields(reports_dir: Path, module: str, mode: str, stat2_path: Path | None) -> dict:
    cell_count = register_cell_count = sequential_cell_count = None

    cells_text = _read(reports_dir / f"{module}.cells.rpt")
    if cells_text is not None:
        kv = parse_keyvalue_report(cells_text)
        cell_count = _to_int(kv.get("Total_cells"))
        register_cell_count = _to_int(kv.get("Register_cells"))
        sequential_cell_count = _to_int(kv.get("Sequential_cells"))

    if cell_count is None or register_cell_count is None or sequential_cell_count is None:
        groups_text = _read(reports_dir / f"{module}.power_groups.rpt")
        if groups_text is not None:
            groups = parse_power_groups(groups_text)
            if register_cell_count is None:
                register_cell_count = groups.get("register")
            if sequential_cell_count is None:
                sequential_cell_count = groups.get("sequential")
            if cell_count is None and groups:
                cell_count = sum(groups.values())

    register_bit_count = cgr = cge = dacge = None
    cge_text = _read(reports_dir / f"{module}.cge.hier.rpt")
    if cge_text is not None:
        cge_row = parse_cge_hier_module_row(cge_text, module)
        if cge_row:
            register_bit_count = cge_row["register_bit_count"]
            cgr, cge, dacge = cge_row["CGR"], cge_row["CGE"], cge_row["DACGE"]

    untraced = None
    if mode == "timebased":
        stat2_text = _read(stat2_path)
        if stat2_text is not None:
            stat2 = parse_keyvalue_report(stat2_text)
            if "Total cell count" in stat2:
                cell_count = _to_int(stat2["Total cell count"])
            if "Register Count" in stat2:
                register_cell_count = _to_int(stat2["Register Count"])
            if "Sequential cells count" in stat2:
                sequential_cell_count = _to_int(stat2["Sequential cells count"])
            if "SCGE" in stat2:
                cgr = _to_float(stat2["SCGE"])
            if "DCGE" in stat2:
                cge = _to_float(stat2["DCGE"])
            if "DACGE" in stat2:
                dacge = _to_float(stat2["DACGE"])
            if "Untraced Sequential ratio" in stat2:
                ratio = _to_float(stat2["Untraced Sequential ratio"])
                if ratio is not None:
                    untraced = round(ratio * 100, 2)

    if untraced is None and register_cell_count is not None and sequential_cell_count is not None:
        denom = register_cell_count + sequential_cell_count
        if denom:
            untraced = round(sequential_cell_count / denom * 100, 2)

    return {
        "cell_count": cell_count,
        "register_cell_count": register_cell_count,
        "sequential_cell_count": sequential_cell_count,
        "register_bit_count": register_bit_count,
        "untraced_sequentials": untraced,
        "CGR": round(cgr, 2) if cgr is not None else None,
        "CGE": round(cge, 2) if cge is not None else None,
        "DACGE": round(dacge, 2) if dacge is not None else None,
    }


# --------------------------------------------------------------------------- #
# Row model: one per (module, power_mode, test_name, instance)
# --------------------------------------------------------------------------- #
@dataclass
class Row:
    module: str
    power_mode: str  # "vectorless" or "timebased"
    test_name: str  # "" for vectorless
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


def read_partition_list(path: Path) -> list[str]:
    """Parse S20 (prep_pprtl2_partition.list): one bare module name per line."""
    text = _read(path)
    if text is None:
        return []
    return [ln.strip() for ln in text.splitlines() if ln.strip() and not ln.strip().startswith("#")]


def build_rows(cfg: Config) -> tuple[list[Row], dict[str, PassCandidate]]:
    candidates = find_pass_candidates(cfg.workarea, cfg.dut)
    chosen = select_newest_per_module(candidates)

    # Every partition in S20 (prep_pprtl2_partition.list) must be accounted for in
    # the CSVs, even if it never reached elab or power (status: "Not Ran"/"Fail=n").
    # When S20 is unavailable (e.g. an ad-hoc single-module workarea with no
    # prep_pprtl2 run), fall back to whatever pass-dirs were actually discovered.
    target_modules = set(read_partition_list(cfg.partition_list)) | set(chosen)
    if not target_modules:
        target_modules = set(chosen)

    rows: list[Row] = []
    for module in sorted(target_modules):
        cand = chosen.get(module)
        if cand is None:
            # Never even started (no flow_inputs/config.log discovered anywhere).
            rows.append(Row(
                module=module, power_mode="", test_name="", instance="",
                elab=StageResult("Not Ran", None, None),
                fsdb=StageResult("Not Ran", None, None),
                power=StageResult("Not Ran", None, None),
            ))
            continue

        pass_dir = cand.pass_dir

        elab_pass = pass_dir / "elab" / "elab.PASS"
        elab_flow_log = pass_dir / "elab" / "log" / "flow.log"
        elab_grdl = grdlbuild_log_path(cfg.workarea, module, "elab")
        elab_result = evaluate_stage(
            pass_marker=elab_pass, flow_log=elab_flow_log, grdlbuild_log=elab_grdl,
        )
        wattson_log = pass_dir / "elab" / "pprtl_work" / "wattson.log"
        vcs_log = pass_dir / "elab" / "pprtl_work" / "vcs" / "vcs.log"
        read_sdc_log = pass_dir / "elab" / "pprtl_work" / "sdc" / "read_sdc.log"

        vectorless_dir = pass_dir / "power" / "vectorless"
        timebased_dir = pass_dir / "power" / "timebased"
        produced_row = False

        if vectorless_dir.is_dir():
            produced_row = True
            reports_dir = vectorless_dir / "default" / "reports"
            power_pass = vectorless_dir / "default" / "vectorless.PASS"
            power_flow_log = vectorless_dir / "default" / "log" / "vectorless.flow.log"
            power_grdl = grdlbuild_log_path(cfg.workarea, module, "power")
            power_result = evaluate_stage(
                pass_marker=power_pass, flow_log=power_flow_log, grdlbuild_log=power_grdl,
            )
            rows.append(Row(
                module=module, power_mode="vectorless", test_name="", instance="",
                elab=elab_result, fsdb=StageResult("Not Required", None, None), power=power_result,
                qor=extract_qor_fields(reports_dir, module, "vectorless", None),
                elab_flow_log=elab_flow_log, elab_grdl_log=elab_grdl,
                power_flow_log=power_flow_log, power_grdl_log=power_grdl,
                wattson_log=wattson_log, vcs_log=vcs_log, read_sdc_log=read_sdc_log,
            ))

        if timebased_dir.is_dir():
            for test_dir in sorted(_iter_subdirs(timebased_dir)):
                for inst_dir in sorted(_iter_subdirs(test_dir)):
                    produced_row = True
                    test_name, instance = test_dir.name, inst_dir.name
                    reports_dir = inst_dir / "reports"
                    stat2_path = reports_dir / f"{module}.stat2.rpt"

                    fsdb_pass = pass_dir / "fsdb" / test_name / instance / "fsdb.PASS"
                    fsdb_flow_log = pass_dir / "fsdb" / test_name / instance / "log" / "flow.log"
                    fsdb_grdl = grdlbuild_log_path(cfg.workarea, module, "fsdb")
                    fsdb_result = evaluate_stage(
                        pass_marker=fsdb_pass, flow_log=fsdb_flow_log, grdlbuild_log=fsdb_grdl,
                    )

                    power_pass = inst_dir / "power.PASS"
                    power_flow_log = inst_dir / "log" / "timebased.flow.log"
                    # NB: grdlbuild's power.<module>.pprtl2_power.log (if any) covers the
                    # WHOLE timebased run across all tests, not this one test -- so this
                    # row's status/runtime/memory must come from its own power.PASS +
                    # timebased.flow.log, not the module-level grdlbuild log.
                    power_result = evaluate_stage(
                        pass_marker=power_pass, flow_log=power_flow_log, grdlbuild_log=None,
                    )

                    rows.append(Row(
                        module=module, power_mode="timebased", test_name=test_name, instance=instance,
                        elab=elab_result, fsdb=fsdb_result, power=power_result,
                        qor=extract_qor_fields(reports_dir, module, "timebased", stat2_path),
                        elab_flow_log=elab_flow_log, elab_grdl_log=elab_grdl,
                        fsdb_flow_log=fsdb_flow_log, fsdb_grdl_log=fsdb_grdl,
                        power_flow_log=power_flow_log, power_grdl_log=None,
                        wattson_log=wattson_log, vcs_log=vcs_log, read_sdc_log=read_sdc_log,
                    ))

        if not produced_row:
            # A pass-dir/config.log was discovered (so elab may be Pass/Fail/Running),
            # but the power stage never started at all -- no power/vectorless or
            # power/timebased dir exists yet. Recover the intended mode from the
            # flow's own config.log (POWER_ANALYSIS_MODE is a run input, written
            # before elab/power ever execute).
            rows.append(Row(
                module=module, power_mode=cand.config.get("POWER_ANALYSIS_MODE", ""),
                test_name="", instance="",
                elab=elab_result,
                fsdb=StageResult("Not Ran", None, None),
                power=StageResult("Not Ran", None, None),
                elab_flow_log=elab_flow_log, elab_grdl_log=elab_grdl,
                wattson_log=wattson_log, vcs_log=vcs_log, read_sdc_log=read_sdc_log,
            ))
    return rows, chosen


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
    "cell_count", "register_cell_count", "sequential_cell_count",
    "register_bit_count", "untraced_sequentials", "CGR", "CGE", "DACGE",
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
                "cell_count": _blank(q.get("cell_count")),
                "register_cell_count": _blank(q.get("register_cell_count")),
                "sequential_cell_count": _blank(q.get("sequential_cell_count")),
                "register_bit_count": _blank(q.get("register_bit_count")),
                "untraced_sequentials": _blank(q.get("untraced_sequentials")),
                "CGR": _blank(q.get("CGR")),
                "CGE": _blank(q.get("CGE")),
                "DACGE": _blank(q.get("DACGE")),
            })


# --------------------------------------------------------------------------- #
# report_pprtl2.summary.md
# --------------------------------------------------------------------------- #
_TOTAL_RE = re.compile(r"^total partitions\s*:\s*(\d+)", re.MULTILINE)
_RAN_RE = re.compile(r"^ran\s*:\s*(\d+)\s*\(([\d.]+)%\)", re.MULTILINE)


def symlink_target(path: Path) -> str:
    """Resolve REF_MODEL/SDC_ARCHIVE to the real path their symlink points at."""
    if not path.exists():
        return "NA"
    try:
        return str(path.resolve())
    except OSError:
        return "NA"


def _has_grdlbuild_log(workarea: Path, module: str) -> bool:
    """True if any of the module's elab/fsdb/power grdlbuild netbatch logs exist
    (complete or partial coverage both count)."""
    return any(
        grdlbuild_log_path(workarea, module, stage).is_file()
        for stage in ("elab", "fsdb", "power")
    )


def _has_stage_flow_log(rows_for_module: list[Row]) -> bool:
    """True if any stage's flow.log file exists on disk for this module's rows."""
    for r in rows_for_module:
        for p in (r.elab_flow_log, r.fsdb_flow_log, r.power_flow_log):
            if p is not None and p.is_file():
                return True
    return False


def render_summary_md(
    cfg: Config, rows: list[Row], chosen: dict[str, PassCandidate], command_line: str = "",
) -> str:
    def pct(numer: int, denom: int) -> float:
        return round(numer / denom * 100, 1) if denom else 0.0

    prep_summary_text = _read(cfg.report_summary) or ""
    total_m = _TOTAL_RE.search(prep_summary_text)
    ran_m = _RAN_RE.search(prep_summary_text)
    total_partitions = int(total_m.group(1)) if total_m else len(chosen)
    ran_count = int(ran_m.group(1)) if ran_m else None
    ran_pct = float(ran_m.group(2)) if ran_m else None

    rows_by_module: dict[str, list[Row]] = {}
    for r in rows:
        rows_by_module.setdefault(r.module, []).append(r)
    all_modules = sorted(rows_by_module)
    grdlbuild_count = sum(1 for m in all_modules if _has_grdlbuild_log(cfg.workarea, m))
    flow_log_count = sum(1 for m in all_modules if _has_stage_flow_log(rows_by_module[m]))

    vec_rows = [r for r in rows if r.power_mode == "vectorless"]
    tb_rows = [r for r in rows if r.power_mode == "timebased"]

    vec_elab_pass = len({r.module for r in vec_rows if r.elab.status == "Pass"})
    vec_power_pass = sum(1 for r in vec_rows if r.power.status == "Pass")

    tb_elab_pass = len({r.module for r in tb_rows if r.elab.status == "Pass"})
    tb_power_pass = sum(1 for r in tb_rows if r.power.status == "Pass")
    multi_test_modules = sorted(
        m for m in {r.module for r in tb_rows}
        if len({r.test_name for r in tb_rows if r.module == m}) > 1
    )

    lines = [
        f"Command Line: {command_line}",
        f"Workarea: {cfg.workarea}",
        f"REF_MODEL: {symlink_target(cfg.ref_model)}",
        f"SDC_ARCHIVE: {symlink_target(cfg.sdc_archive)}",
        f"DUT: {cfg.dut}",
        f"total partitions {total_partitions}",
    ]
    if ran_count is not None and ran_pct is not None:
        lines.append(f"total partitions pass pre-flight {ran_count}  {ran_pct}%")
    lines.append(
        f"total partitions with at least one grdlbuild log: {grdlbuild_count}  "
        f"{pct(grdlbuild_count, total_partitions)}%"
    )
    lines.append(
        f"total partitions with at least one stage flow.log file: {flow_log_count}  "
        f"{pct(flow_log_count, total_partitions)}%"
    )
    lines += [
        "",
        "vectorless:",
        f"total partitions pass elab: {vec_elab_pass}  {pct(vec_elab_pass, total_partitions)}%",
        f"total partitions pass vectorless power: {vec_power_pass}  {pct(vec_power_pass, total_partitions)}%",
        "",
        "timebased:",
        f"total partitions pass elab: {tb_elab_pass}  {pct(tb_elab_pass, total_partitions)}%",
        f"total partitions pass timebased power: {tb_power_pass}  {pct(tb_power_pass, total_partitions)}%",
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
# report_pprtl2.terminology.md (static content, direct write, spec section 3.7)
# --------------------------------------------------------------------------- #
TERMINOLOGY_MD = """\
# PPRTL1 vs PPRTL2 Terminology

| Metric | PPRTL1 | PPRTL2 |
|---|---|---|
| % clock gated registers (static) | Static Clock Gating Efficiency (SCGE) | Clock Gating Ratio (CGR) |
| % gated clock cycles; lacks correlation with data activity | Dynamic Clock Gating Efficiency (DCGE) | Clock Gating Efficiency (CGE) |
| CGE +  [data toggle cycles / root clock cycles] | Data Aware Clock Gating Efficiency (DACGE) | Data Aware Clock Gating Efficiency (DACGE) |
| % untraced sequentials | - | Untraced Sequentials (%) |

**Notes:**
- Static CGE is your upper bounds
- DACGE will be the same or higher than CGE/DCGE by nature of the arithmetic.
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


def generate_reports(cfg: Config, command_line: str = "") -> tuple[list[Row], dict[str, PassCandidate]]:
    rows, chosen = build_rows(cfg)
    write_compute_csv(cfg, rows)
    write_qor_csv(cfg, rows)
    cfg.summary_md.write_text(render_summary_md(cfg, rows, chosen, command_line), encoding="utf-8")
    cfg.fail_details.write_text(render_fail_details(rows), encoding="utf-8")
    cfg.terminology_md.write_text(TERMINOLOGY_MD, encoding="utf-8")
    return rows, chosen


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)
    cfg = resolve_config(args)

    errors = preflight(cfg)
    if errors:
        for e in errors:
            print(f"-E- {e}", file=sys.stderr)
        return 2

    rows, chosen = build_rows(cfg)
    if not rows:
        print("-E- No power run areas discovered.", file=sys.stderr)
        return 2

    if args.dry_run:
        print("Would write:")
        for p in (cfg.summary_md, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.terminology_md):
            print(f"  {p}")
        print(f"Discovered {len(chosen)} module(s), {len(rows)} row(s).")
        return 0

    # Reuse the already-built rows/chosen (avoid re-scanning the whole run area).
    write_compute_csv(cfg, rows)
    write_qor_csv(cfg, rows)
    cfg.summary_md.write_text(render_summary_md(cfg, rows, chosen, _command_line(argv)), encoding="utf-8")
    cfg.fail_details.write_text(render_fail_details(rows), encoding="utf-8")
    cfg.terminology_md.write_text(TERMINOLOGY_MD, encoding="utf-8")

    if args.verbose:
        for p in (cfg.summary_md, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.terminology_md):
            print(f"wrote {p}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
