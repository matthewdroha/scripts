"""Command line interface for find_collisions."""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from collections.abc import Sequence
from pathlib import Path

from find_collisions.collisions import (
    INSTANCE_FIELDS,
    RAW_FIELDS,
    all_configrule_values,
    build_realpath_counts,
    collect_instance_rows,
    collect_raw_rows,
    collect_reduced_rows,
    colliding_modules,
    filter_counts,
    reduced_fields,
)
from find_collisions.paranoia import build_checker, paranoia_lines
from find_collisions.paths import Inputs, PreflightError, resolve_inputs
from find_collisions.patterns import (
    EXACT,
    PATTERN_FIELDS,
    Matcher,
    Pattern,
    load_patterns,
    pattern_rows,
)
from find_collisions.report import (
    EXCEL_MAX_ROWS,
    MODULE_XLSX_NAME,
    REPORT_NAME,
    XLSX_NAME,
    Sheet,
    input_lines,
    summary_lines,
    write_excel_workbook,
    write_summary,
)
from find_collisions.xmlstream import Definition, Scan, scan_dump

EXIT_PREFLIGHT = 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="find_collisions",
        description="Report RTL modules bound to more than one definition.",
    )
    parser.add_argument(
        "--fe_collateral",
        required=True,
        type=Path,
        help="top level fe_collateral directory of the handoff workarea",
    )
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument(
        "--module", help="a single module name to expand into the module workbook"
    )
    selection.add_argument(
        "--modulefile",
        type=Path,
        help="file of module names / r\"regex\" patterns to expand into the module workbook",
    )
    parser.add_argument(
        "--paranoia",
        action="store_true",
        help="cross-check the XML against the fullchipdump and _cfg.sv (reports only, never fails)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the plan and exit without parsing the XML or writing output",
    )
    parser.add_argument(
        "--force", action="store_true", help="accepted for CLI parity; reports always regenerate"
    )
    parser.add_argument("--verbose", action="store_true", help="log parse progress")
    return parser


def _plan_lines(inputs: Inputs, outdir: Path, modulefile: Path | None, module: bool) -> list[str]:
    lines = [
        f"REF_MODEL: {inputs.ref_model}",
        f"DUT:       {inputs.dut}",
        f"BLOCK:     {inputs.block}",
        *input_lines(inputs, modulefile),
    ]
    lines.append(f"would write: {outdir / XLSX_NAME}")
    if modulefile is not None or module:
        lines.append(f"would write: {outdir / MODULE_XLSX_NAME}")
    lines.append(f"would write: {outdir / REPORT_NAME}")
    return lines


def _collision_sheets(
    counts: Counter[Definition],
    configrule_columns: Sequence[str],
) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    """The raw and (realpath-collapsed) reduced rows for a set of definition counts."""
    raw_rows = collect_raw_rows(counts)
    realpath_counts = build_realpath_counts(counts, modules=colliding_modules(counts))
    reduced_rows = collect_reduced_rows(realpath_counts, configrule_columns)
    return raw_rows, reduced_rows


def _module_workbook_sheets(
    scan: Scan,
    patterns: Sequence[Pattern],
    matcher: Matcher,
    configrule_columns: Sequence[str],
    notes: list[str],
) -> list[Sheet]:
    matched = {d.module for d in scan.counts if matcher(d.module)}
    module_counts = filter_counts(scan.counts, matched)
    raw_rows, reduced_rows = _collision_sheets(module_counts, configrule_columns)
    instance_rows = collect_instance_rows(scan.instances)
    dropped = len(instance_rows) - (EXCEL_MAX_ROWS - 1)
    if dropped > 0:
        instance_rows = instance_rows[: EXCEL_MAX_ROWS - 1]
        notes.append(f"instances sheet hit Excel's row limit; {dropped:,} rows dropped")
    return [
        ("patterns", pattern_rows(patterns, sorted(matched)), PATTERN_FIELDS),
        ("raw", raw_rows, RAW_FIELDS),
        ("reduced", reduced_rows, reduced_fields(configrule_columns)),
        ("instances", instance_rows, INSTANCE_FIELDS),
    ]


def main(argv: Sequence[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    args = build_parser().parse_args(argv)

    try:
        inputs = resolve_inputs(args.fe_collateral)
        patterns: list[Pattern] | None = None
        if args.modulefile:
            patterns = load_patterns(args.modulefile)
        elif args.module:
            patterns = [Pattern(raw=args.module, kind=EXACT)]
    except PreflightError as exc:
        print(f"find_collisions: {exc}", file=sys.stderr)
        return EXIT_PREFLIGHT

    outdir = Path.cwd()
    if args.dry_run:
        print("\n".join(_plan_lines(inputs, outdir, args.modulefile, bool(args.module))))
        return 0

    # flushed: a redirected run is otherwise block-buffered and shows no progress
    log = (
        (lambda message: print(f"find_collisions: {message}", flush=True))
        if args.verbose
        else None
    )
    matcher = Matcher(patterns) if patterns else None
    checker = (
        build_checker(inputs.fullchipdump, inputs.cfg_sv, log=log) if args.paranoia else None
    )
    scan = scan_dump(inputs.config_xml, log=log, want_details=matcher, observe=checker)
    configrule_columns = all_configrule_values(scan.counts)

    raw_rows, reduced_rows = _collision_sheets(scan.counts, configrule_columns)

    xlsx_path = outdir / XLSX_NAME
    write_excel_workbook(
        xlsx_path,
        [
            ("raw", raw_rows, RAW_FIELDS),
            ("reduced", reduced_rows, reduced_fields(configrule_columns)),
        ],
    )
    outputs = [(XLSX_NAME, [("raw", len(raw_rows)), ("reduced", len(reduced_rows))])]
    written = [xlsx_path]

    notes: list[str] = []
    if patterns and matcher:
        sheets = _module_workbook_sheets(scan, patterns, matcher, configrule_columns, notes)
        module_path = outdir / MODULE_XLSX_NAME
        write_excel_workbook(module_path, sheets)
        outputs.append((MODULE_XLSX_NAME, [(name, len(rows)) for name, rows, _ in sheets]))
        written.append(module_path)

    lines = summary_lines(
        ["find_collisions", *argv],
        inputs,
        outputs,
        modulefile=args.modulefile,
        patterns=[pattern.raw for pattern in patterns or []],
        paranoia=paranoia_lines(checker.result()) if checker else (),
        notes=notes,
    )
    report_path = outdir / REPORT_NAME
    write_summary(report_path, lines)
    print("\n".join(lines))
    if log:
        for path in [*written, report_path]:
            log(f"wrote {path}")
    return 0
