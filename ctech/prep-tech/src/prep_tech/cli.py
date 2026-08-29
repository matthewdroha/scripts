"""Command-line entry point for prep_tech."""

from __future__ import annotations

import argparse
import os
import sys
from collections.abc import Sequence

from . import config, generate, validate

PROG = "prep_tech"

EXIT_OK = 0
EXIT_DUPLICATES = 1
EXIT_PREFLIGHT = 2


class PrepTechError(Exception):
    """Fatal, user-facing error (bad input, missing path, unwritable output)."""


def default_output_root() -> str:
    workarea = os.environ.get("WORKAREA")
    base = workarea if workarea else os.getcwd()
    return os.path.join(base, "prep_tech")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog=PROG,
        description=(
            "Prepare the Cheetah process technology list files for ctech and "
            "synthesis. Generative and idempotent: the same inputs always "
            "reproduce the same output tree."
        ),
    )
    parser.add_argument(
        "input_md",
        help="path to prep_tech.input.md (die sections, ctech dirs, config files)",
    )
    parser.add_argument(
        "-o",
        "--output-root",
        default=None,
        help=(
            "directory to write the generated tree into "
            "(default: $WORKAREA/prep_tech, else ./prep_tech)"
        ),
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="parse and validate the input only; print an OK summary and exit",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="validate and print every path that would be written; write nothing",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help=(
            "accepted for consistency; every run regenerates the whole tree in "
            "place, so this flag changes nothing"
        ),
    )
    parser.add_argument(
        "--allow-duplicates",
        action="store_true",
        help=(
            "continue when several configuration files define the same stdcell "
            "(first configuration wins); duplicates are always reported"
        ),
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="log progress to stdout while resolving and writing",
    )
    return parser


def _load(args) -> tuple[dict, str]:
    if not os.path.isfile(args.input_md):
        raise PrepTechError(f"input file not found: {args.input_md}")
    try:
        parsed = config.parse_input(args.input_md)
    except config.InputFormatError as exc:
        raise PrepTechError(str(exc)) from exc
    if not parsed["dies"]:
        raise PrepTechError(f"no die or IP sections found in {args.input_md}")

    output_root = args.output_root or default_output_root()
    try:
        validate.pre_flight_validation(parsed["dies"], output_root)
    except (FileNotFoundError, PermissionError, ValueError) as exc:
        raise PrepTechError(str(exc)) from exc
    return parsed, output_root


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    log = (lambda m: print(f"{PROG}: {m}", flush=True)) if args.verbose else None

    try:
        parsed, output_root = _load(args)
    except PrepTechError as exc:
        print(f"{PROG}: {exc}", file=sys.stderr)
        return EXIT_PREFLIGHT

    dies = parsed["dies"]
    if args.check:
        configs = sum(len(d["config_files"]) for d in dies.values())
        ctechs = sum(len(d["ctech_dirs"]) for d in dies.values())
        print(
            f"{PROG}: OK - {len(dies)} dies, {configs} configuration files, "
            f"{ctechs} ctech directories; output root {output_root}"
        )
        return EXIT_OK

    if args.dry_run:
        plans = generate.plan_all(parsed, log=log)
        for die, plan in plans:
            print(generate.die_summary(die, plan))
        for path in generate.planned_outputs(plans, output_root):
            print(f"would write: {path}")
        return EXIT_OK

    written, plans, has_duplicates = generate.generate_all(
        parsed, output_root, allow_duplicates=args.allow_duplicates, log=log
    )
    for die, plan in plans:
        print(generate.die_summary(die, plan))
    print(f"{PROG}: wrote {len(written)} files under {output_root}")

    if has_duplicates and not args.allow_duplicates:
        print(
            f"{PROG}: duplicate stdcell definitions found; see "
            f"{os.path.join(output_root, 'prep_tech.duplicates.csv')} "
            "(re-run with --allow-duplicates to continue)",
            file=sys.stderr,
        )
        return EXIT_DUPLICATES
    return EXIT_OK
