#!/usr/bin/env python3
"""compare_pprtl2 — cross-run comparison / trend analysis of pprtl2 report data.

Reads the ``report_pprtl2`` CSV outputs from N pprtl2 workareas (one per
"model", listed in a markdown file) and emits per-metric percentage-difference
reports so power/QoR/compute trends across models, dates and tool versions are
visible at a glance.

See scripts/pprtl2/compare_pprtl2.spec.md for the full specification and
scripts/pprtl2/test_compare_pprtl2.py for the fixture-driven unit tests.

Phase 1-3 (this file): models-file parsing, pre-flight validation, metric
derivation, % diff computation, comparison-row building and report writing.
Enhancements: non-passing power runs report their status instead of bogus
numbers (§3.5), a status/tool-version report (§3.6), and chained neighbour
deltas alongside the baseline deltas (§3.7).

Notes worth carrying (verified against real workareas, see
/memories/repo/compare_pprtl2.md):
  - The compare key is module+power_mode+test_name+``instance``. Without
    ``instance`` it is NOT unique: real timebased runs put several instances
    under one test name.
  - A blank ``test_name`` is normalized to "default" for *vectorless* rows only.
    Timebased rows with a blank test_name are report_pprtl2's "no test directory
    yet" fallback rows and must keep the blank, or they would collide with
    unrelated keys.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator

# The four columns that together form the compare key (spec §2.3).
KEY_COLUMNS = ("module", "power_mode", "test_name", "instance")

CompareKey = tuple[str, str, str, str]

_MODEL_LINE_RE = re.compile(r"^\s*(\S+)\s*=\s*(\S+)(\s+.*)?$")

# Non-numeric source columns that never become metric rows (spec §3.2/§3.3).
_STATUS_COLUMNS = ("elab_run_status", "fsdb_run_status", "power_run_status")

# The only status that gates the value columns; elab/fsdb are ignored (spec §3.5).
POWER_STATUS_COLUMN = "power_run_status"
PASS_STATUS = "Pass"


@dataclass(frozen=True)
class ReportKind:
    """One of the two report_pprtl2 CSVs and its compare_pprtl2 counterpart."""

    name: str
    source_filename: str
    output_filename: str
    excluded: tuple[str, ...]
    # When set, the metric list is exactly these columns instead of the union (§3.6).
    included: tuple[str, ...] = ()
    # "percent" -> numeric % diff columns; "match" -> same/changed columns (§3.6).
    comparison: str = "percent"

    @property
    def substitutes_failed_runs(self) -> bool:
        """§3.5 hides numbers behind a status; the status report must show them."""
        return self.comparison == "percent"

    @property
    def diff_suffix(self) -> str:
        return "% diff" if self.comparison == "percent" else "change"


QOR = ReportKind(
    name="qor",
    source_filename="report_pprtl2.qor.csv",
    output_filename="compare_pprtl2.qor.csv",
    excluded=(*_STATUS_COLUMNS, "VCS_VERSION", "VERDI_VERSION", "PPRTL_VERSION"),
)

COMPUTE = ReportKind(
    name="compute",
    source_filename="report_pprtl2.compute.csv",
    output_filename="compare_pprtl2.compute.csv",
    # The *_runtime_seconds columns survive only as % diff backing values (§3.4).
    excluded=(
        *_STATUS_COLUMNS,
        "elab_runtime_seconds",
        "fsdb_runtime_seconds",
        "power_runtime_seconds",
        "total_runtime_seconds",
    ),
)

# Statuses are identical in both source CSVs and the versions live only in qor,
# so the status report reads qor alone (verified 2026-08-13, spec §3.6).
STATUS = ReportKind(
    name="status",
    source_filename="report_pprtl2.qor.csv",
    output_filename="compare_pprtl2.status.csv",
    excluded=(),
    included=(*_STATUS_COLUMNS, "VCS_VERSION", "VERDI_VERSION", "PPRTL_VERSION"),
    comparison="match",
)

REPORT_KINDS = (QOR, COMPUTE, STATUS)


# --------------------------------------------------------------------------- #
# Config
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class ModelEntry:
    """One ``<model> = <workarea>`` pair from the models file (S1)."""

    name: str
    workarea: Path

    @property
    def report_root(self) -> Path:
        return self.workarea / "power" / "pprtl2"

    def source_csv(self, kind: ReportKind) -> Path:
        return self.report_root / kind.source_filename

    @property
    def compute_csv(self) -> Path:
        return self.source_csv(COMPUTE)

    @property
    def qor_csv(self) -> Path:
        return self.source_csv(QOR)


@dataclass(frozen=True)
class Config:
    """Fully-resolved run configuration."""

    models: tuple[ModelEntry, ...]
    outdir: Path

    @property
    def baseline(self) -> ModelEntry:
        return self.models[0]

    def output_path(self, kind: ReportKind) -> Path:
        return self.outdir / kind.output_filename

    @property
    def compare_qor_csv(self) -> Path:
        return self.output_path(QOR)

    @property
    def compare_compute_csv(self) -> Path:
        return self.output_path(COMPUTE)

    @property
    def compare_status_csv(self) -> Path:
        return self.output_path(STATUS)


# --------------------------------------------------------------------------- #
# S1 — models file
# --------------------------------------------------------------------------- #
def read_models_file(path: Path) -> list[ModelEntry]:
    """Parse the ``<model> = <workarea>`` list (spec §2.2), preserving order.

    The first entry is the baseline. Raises ValueError with a printable message
    on any malformed/duplicate/insufficient input -- a typo'd path must never be
    silently skipped.
    """
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ValueError(f"cannot read models file: {exc}") from exc

    entries: list[ModelEntry] = []
    seen: set[str] = set()
    for lineno, raw in enumerate(text.splitlines(), 1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = _MODEL_LINE_RE.match(raw)
        if not match:
            raise ValueError(f"{path}:{lineno}: expected '<model> = <workarea>', got: {stripped}")
        name, workarea = match.group(1), match.group(2)
        if "," in name or '"' in name:
            raise ValueError(f"{path}:{lineno}: model name may not contain ',' or '\"': {name}")
        if name in seen:
            raise ValueError(f"{path}:{lineno}: duplicate model name: {name}")
        seen.add(name)
        entries.append(ModelEntry(name=name, workarea=Path(workarea).expanduser()))

    if len(entries) < 2:
        raise ValueError(
            f"{path}: need at least 2 '<model> = <workarea>' entries to compare, found {len(entries)}"
        )
    return entries


# --------------------------------------------------------------------------- #
# S3/S4 — report_pprtl2 CSV reading
# --------------------------------------------------------------------------- #
def _uncommented(lines: Iterable[str]) -> Iterator[str]:
    """Drop ``#`` comment lines (spec §2.3; report_pprtl2 emits none today)."""
    for line in lines:
        if line.lstrip().startswith("#"):
            continue
        yield line


def _clean(value: object) -> str:
    """Normalize one DictReader cell: ragged rows yield None (short) or list (long)."""
    if value is None:
        return ""
    if isinstance(value, list):
        return ",".join(str(v).strip() for v in value)
    return str(value).strip()


def read_report_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Read a report_pprtl2 CSV into (header, rows), stripping every field."""
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(_uncommented(handle))
        fieldnames = [f.strip() for f in (reader.fieldnames or [])]
        rows = [{_clean(k): _clean(v) for k, v in row.items()} for row in reader]
    return fieldnames, rows


def row_key(row: dict[str, str]) -> CompareKey:
    """Compare key for a report_pprtl2 row, with the §2.3 test_name normalization."""
    module = row.get("module", "").strip()
    power_mode = row.get("power_mode", "").strip()
    test_name = row.get("test_name", "").strip()
    instance = row.get("instance", "").strip()
    if not test_name and power_mode == "vectorless":
        test_name = "default"
    return (module, power_mode, test_name, instance)


def _check_report_csv(path: Path, errors: list[str]) -> None:
    """Append any header/duplicate-key problems found in one source CSV."""
    if not path.is_file():
        errors.append(f"missing report_pprtl2 output: {path}")
        return
    try:
        fieldnames, rows = read_report_csv(path)
    except OSError as exc:
        errors.append(f"cannot read {path}: {exc}")
        return

    missing = [c for c in KEY_COLUMNS if c not in fieldnames]
    if missing:
        errors.append(f"{path}: header is missing key column(s): {', '.join(missing)}")
        return

    seen: set[CompareKey] = set()
    for key in (row_key(r) for r in rows):
        if key in seen:
            errors.append(f"{path}: duplicate compare key: {','.join(key)}")
        seen.add(key)


# --------------------------------------------------------------------------- #
# Pre-flight
# --------------------------------------------------------------------------- #
def preflight(cfg: Config) -> list[str]:
    """Validate every input before anything is written (spec §2.1)."""
    errors: list[str] = []

    if not cfg.outdir.is_dir():
        errors.append(f"--outdir does not exist: {cfg.outdir}")

    for model in cfg.models:
        if not model.workarea.is_dir():
            errors.append(f"[{model.name}] workarea not found: {model.workarea}")
            continue
        _check_report_csv(model.compute_csv, errors)
        _check_report_csv(model.qor_csv, errors)

    return errors


# --------------------------------------------------------------------------- #
# Metric derivation
# --------------------------------------------------------------------------- #
def derive_metrics(kind: ReportKind, headers: Iterable[Iterable[str]]) -> list[str]:
    """Union of the models' source columns, in first-seen header order, minus the
    key columns and ``kind``'s exclusion list (spec §3.1/§6 Q8).

    Derived rather than hardcoded so new report_pprtl2 columns flow through
    without a code change.
    """
    headers = [list(h) for h in headers]  # callers pass a generator; used twice below
    present = {c for header in headers for c in header}
    if kind.included:
        return [c for c in kind.included if c in present]

    metrics: list[str] = []
    seen: set[str] = set()
    for header in headers:
        for column in header:
            if column in KEY_COLUMNS or column in kind.excluded or column in seen:
                continue
            seen.add(column)
            metrics.append(column)
    return metrics


# --------------------------------------------------------------------------- #
# Numeric backing values and % diff (spec §3.4)
# --------------------------------------------------------------------------- #
_MEMORY_RE = re.compile(r"^\s*([0-9]*\.?[0-9]+)\s*([KMGT]?B)\s*$", re.IGNORECASE)

# Decimal (1000-based) factors, matching report_pprtl2's own mem_gb = mem_mb / 1000.
_MEMORY_SCALE = {"B": 1.0, "KB": 1e3, "MB": 1e6, "GB": 1e9, "TB": 1e12}


def _to_float(value: str) -> float | None:
    try:
        return float(value.replace(",", ""))
    except (AttributeError, ValueError):
        return None


def parse_memory(value: str) -> float | None:
    """``"12.63 GB"`` -> bytes as a float; None if the shape isn't recognized."""
    match = _MEMORY_RE.match(value or "")
    if not match:
        return None
    return float(match.group(1)) * _MEMORY_SCALE[match.group(2).upper()]


def backing_value(metric: str, row: dict[str, str] | None) -> float | None:
    """The number a metric's % diff is computed from; None means non-numeric."""
    if row is None:
        return None
    if metric.endswith("_runtime"):
        return _to_float(row.get(f"{metric}_seconds", ""))
    if metric.endswith("_peak_memory"):
        return parse_memory(row.get(metric, ""))
    return _to_float(row.get(metric, ""))


def percent_diff(baseline: float | None, value: float | None) -> str:
    """Percent change vs. the baseline; blank when either side is unusable."""
    if baseline is None or value is None or baseline == 0:
        return ""
    return f"{(value - baseline) / baseline * 100:.2f}"


def status_label(row: dict[str, str] | None) -> str:
    """Status to show instead of a non-passing run's blank/bogus numbers (spec §3.5).

    Blank when the run passed, so callers can treat "" as "use the real value".
    The exit code is dropped: ``Fail=2`` -> ``Fail``.
    """
    if row is None:
        return ""
    status = _clean(row.get(POWER_STATUS_COLUMN, ""))
    if not status or status == PASS_STATUS:
        return ""
    return status.split("=", 1)[0].strip()


def comparison_pairs(count: int) -> list[tuple[int, int]]:
    """Model index pairs to compare: every model vs. the baseline, then the chained
    neighbour pairs (spec §3.7).

    The chain's first link (model 2 vs. model 1) is by definition the baseline
    comparison, so it is not repeated; chaining therefore adds columns only from
    the third model on.
    """
    baseline = [(0, i) for i in range(1, count)]
    chained = [(i - 1, i) for i in range(2, count)]
    return baseline + chained


def match_indicator(
    left: dict[str, str] | None, right: dict[str, str] | None, metric: str
) -> str:
    """``same``/``changed`` for non-numeric items; blank if either side is absent."""
    if left is None or right is None:
        return ""
    return "same" if _clean(left.get(metric, "")) == _clean(right.get(metric, "")) else "changed"


# --------------------------------------------------------------------------- #
# Table building
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class ModelData:
    """One model's rows from one source CSV, indexed by compare key."""

    model: ModelEntry
    header: list[str]
    rows: dict[CompareKey, dict[str, str]]


@dataclass(frozen=True)
class CompareTable:
    """A fully-built comparison report, ready to write."""

    kind: ReportKind
    header: list[str]
    metrics: list[str]
    keys: list[CompareKey]
    rows: list[list[str]]


def load_model_data(model: ModelEntry, kind: ReportKind) -> ModelData:
    header, rows = read_report_csv(model.source_csv(kind))
    return ModelData(model=model, header=header, rows={row_key(r): r for r in rows})


def build_output_header(cfg: Config, kind: ReportKind, metrics_column: str = "metric") -> list[str]:
    names = [m.name for m in cfg.models]
    return [
        *KEY_COLUMNS,
        metrics_column,
        *names,
        *[
            f"{names[j]} vs {names[i]} {kind.diff_suffix}"
            for i, j in comparison_pairs(len(names))
        ],
    ]


def build_table(cfg: Config, kind: ReportKind) -> CompareTable:
    """Load every model's CSV and build the (key × metric) comparison rows."""
    datasets = [load_model_data(m, kind) for m in cfg.models]
    metrics = derive_metrics(kind, (d.header for d in datasets))
    keys = sorted({key for d in datasets for key in d.rows})
    pairs = comparison_pairs(len(datasets))

    rows: list[list[str]] = []
    for key in keys:
        per_model = [d.rows.get(key) for d in datasets]
        labels = [
            status_label(r) if kind.substitutes_failed_runs else "" for r in per_model
        ]
        for metric in metrics:
            values = [
                label or ("" if r is None else r.get(metric, ""))
                for r, label in zip(per_model, labels)
            ]
            if kind.comparison == "percent":
                backings = [
                    None if label else backing_value(metric, r)
                    for r, label in zip(per_model, labels)
                ]
                diffs = [percent_diff(backings[i], backings[j]) for i, j in pairs]
            else:
                diffs = [
                    match_indicator(per_model[i], per_model[j], metric) for i, j in pairs
                ]
            rows.append([*key, metric, *values, *diffs])

    return CompareTable(
        kind=kind,
        header=build_output_header(cfg, kind),
        metrics=metrics,
        keys=keys,
        rows=rows,
    )


# --------------------------------------------------------------------------- #
# Report writing
# --------------------------------------------------------------------------- #
def write_table(path: Path, table: CompareTable) -> None:
    """Write one comparison CSV, overwriting any prior copy (spec §3)."""
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(table.header)
        writer.writerows(table.rows)


def generate_reports(cfg: Config, tables: Iterable[CompareTable] | None = None) -> list[Path]:
    """Write both comparison CSVs; returns the paths written."""
    if tables is None:
        tables = [build_table(cfg, kind) for kind in REPORT_KINDS]
    written = []
    for table in tables:
        path = cfg.output_path(table.kind)
        write_table(path, table)
        written.append(path)
    return written


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="compare_pprtl2.py",
        description="Compare report_pprtl2 outputs across multiple pprtl2 workareas.",
    )
    parser.add_argument(
        "--models-for-compare", required=True, type=Path,
        help="Markdown file listing '<model> = <workarea>' pairs; the first is the baseline.",
    )
    parser.add_argument(
        "--outdir", type=Path, default=None,
        help="Directory to write the compare reports into (default: cwd). Must already exist.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print the plan; write nothing.")
    parser.add_argument(
        "--force", action="store_true",
        help="No-op: reports are always regenerated/overwritten each run. Kept for CLI parity.",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose logging.")
    return parser


def resolve_config(args: argparse.Namespace) -> Config:
    """Build the Config. Raises ValueError if the models file is unusable."""
    models = read_models_file(args.models_for_compare)
    outdir = args.outdir if args.outdir is not None else Path.cwd()
    return Config(models=tuple(models), outdir=outdir)


def render_plan(cfg: Config, tables: Iterable[CompareTable] = ()) -> list[str]:
    """Human-readable summary of what a run would read and write."""
    lines = ["Would write:"]
    counts = {t.kind.name: t for t in tables}
    for kind in REPORT_KINDS:
        table = counts.get(kind.name)
        detail = ""
        if table is not None:
            detail = (
                f"  ({len(table.keys)} key(s) x {len(table.metrics)} metric(s)"
                f" = {len(table.rows)} row(s))"
            )
        lines.append(f"  {cfg.output_path(kind)}{detail}")
    lines.append(f"Baseline model: {cfg.baseline.name} = {cfg.baseline.workarea}")
    lines.append("Compared against baseline:")
    for model in cfg.models[1:]:
        lines.append(f"  {model.name} = {model.workarea}")
    if len(cfg.models) > 2:
        lines.append("Chain order: " + " -> ".join(m.name for m in cfg.models))
    return lines


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)

    try:
        cfg = resolve_config(args)
    except ValueError as exc:
        print(f"-E- {exc}", file=sys.stderr)
        return 2

    errors = preflight(cfg)
    if errors:
        for e in errors:
            print(f"-E- {e}", file=sys.stderr)
        return 2

    if args.verbose:
        for model in cfg.models:
            print(f"model {model.name}: {model.report_root}")

    tables = [build_table(cfg, kind) for kind in REPORT_KINDS]
    if args.dry_run:
        print("\n".join(render_plan(cfg, tables)))
        return 0

    for path, table in zip(generate_reports(cfg, tables), tables):
        if args.verbose:
            print(f"wrote {path} ({len(table.rows)} row(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
