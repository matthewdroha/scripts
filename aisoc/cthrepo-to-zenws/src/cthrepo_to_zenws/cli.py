"""Command line entry point."""

from __future__ import annotations

import argparse
import shlex
import sys
import time
from pathlib import Path
from typing import Callable, Sequence

from cthrepo_to_zenws.gitdiff import diff_changes, diff_command, is_git_repo, rev_exists
from cthrepo_to_zenws.outputs import OUTPUT_PREFIX, RunInfo, bucket_counts, write_outputs
from cthrepo_to_zenws.plan import AUTO_BUCKETS, NO_ACTION_BUCKETS, build_plan, parse_pattern_file
from cthrepo_to_zenws.workspace import find_migration_report, load_workspace

Log = Callable[[str], None] | None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog=OUTPUT_PREFIX,
        description=(
            "Plan the graft of changes made between two Cheetah repo tags into a "
            "zen workspace, and emit a replay script, summary and CSV plan."
        ),
    )
    parser.add_argument("--cheetah-repo", type=Path, required=True, help="Cheetah git repo")
    parser.add_argument("--zenws-repo", type=Path, required=True, help="Zen workspace root")
    parser.add_argument(
        "--cheetah-tag-used-for-existing-zenws",
        required=True,
        metavar="TAG",
        help="Tag the zen workspace was migrated from (base)",
    )
    parser.add_argument(
        "--cheetah-tag-to-graft-to-zenws",
        required=True,
        metavar="TAG",
        help="Tag whose changes should be grafted (head)",
    )
    parser.add_argument(
        "--migration-report", type=Path, help="Override the discovered migration_report.txt"
    )
    parser.add_argument(
        "--ignore", type=Path, help="File of fnmatch patterns of cheetah paths to skip"
    )
    parser.add_argument("--outdir", type=Path, help="Where to write outputs (default: workspace)")
    parser.add_argument("--dry-run", action="store_true", help="Plan only; write no files")
    parser.add_argument("--force", action="store_true", help="Overwrite existing output files")
    parser.add_argument("--verbose", action="store_true", help="Report progress on stderr")
    parser.add_argument(
        "--debug", type=int, default=0, choices=range(6), metavar="0-5", help="Log detail level"
    )
    return parser


def validate_inputs(args: argparse.Namespace) -> list[str]:
    problems: list[str] = []
    repo = args.cheetah_repo
    if not repo.is_dir():
        problems.append(f"cheetah repo not found: {repo}")
    elif not is_git_repo(repo):
        problems.append(f"not a git repository: {repo}")
    else:
        for tag in (args.cheetah_tag_used_for_existing_zenws, args.cheetah_tag_to_graft_to_zenws):
            if not rev_exists(repo, tag):
                problems.append(f"tag not found in {repo}: {tag}")

    if not args.zenws_repo.is_dir():
        problems.append(f"zen workspace not found: {args.zenws_repo}")
    elif args.migration_report is None and find_migration_report(args.zenws_repo) is None:
        problems.append(f"no */migration_report.txt under {args.zenws_repo}")

    if args.migration_report is not None and not args.migration_report.is_file():
        problems.append(f"migration report not found: {args.migration_report}")
    if args.ignore is not None and not args.ignore.is_file():
        problems.append(f"ignore file not found: {args.ignore}")
    return problems


def main(argv: Sequence[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    args = build_parser().parse_args(argv)
    start = time.time()

    log: Log = (
        (lambda message: print(f"{OUTPUT_PREFIX}: {message}", file=sys.stderr, flush=True))
        if args.verbose
        else None
    )

    problems = validate_inputs(args)
    if problems:
        for problem in problems:
            print(f"{OUTPUT_PREFIX}: error: {problem}", file=sys.stderr)
        return 2

    base_tag = args.cheetah_tag_used_for_existing_zenws
    head_tag = args.cheetah_tag_to_graft_to_zenws

    if log:
        log(f"loading zen workspace {args.zenws_repo}")
    ws = load_workspace(args.zenws_repo, args.migration_report)
    if log:
        log(f"{len(ws.mapping)} mapping entries, {len(ws.category_rules)} category rules")

    changes = diff_changes(args.cheetah_repo, base_tag, head_tag)
    if log:
        log(f"{len(changes)} changed files between {base_tag} and {head_tag}")

    ignore = parse_pattern_file(args.ignore) if args.ignore else []
    rows = build_plan(changes, ws, args.cheetah_repo, base_tag, head_tag, ignore)

    info = RunInfo(
        command_line=shlex.join([OUTPUT_PREFIX, *argv]),
        cheetah_repo=args.cheetah_repo.resolve(),
        zenws_repo=args.zenws_repo.resolve(),
        dest_root=ws.dest_root.resolve(),
        base_tag=base_tag,
        head_tag=head_tag,
        diff_command=diff_command(base_tag, head_tag),
        report_path=args.migration_report or find_migration_report(args.zenws_repo),
        mapping_entries=len(ws.mapping),
        category_rules=len(ws.category_rules),
        start_epoch=start,
        end_epoch=time.time(),
    )

    automatable = sum(n for bucket, n in bucket_counts(rows) if bucket in AUTO_BUCKETS)
    no_action = sum(n for bucket, n in bucket_counts(rows) if bucket in NO_ACTION_BUCKETS)
    print(
        f"{len(rows)} changed files: {automatable} automatable, "
        f"{len(rows) - automatable - no_action} need review, {no_action} no action"
    )

    if args.dry_run:
        if log:
            log("dry run; no files written")
        return 0

    outdir = args.outdir or args.zenws_repo
    outdir.mkdir(parents=True, exist_ok=True)
    try:
        written = write_outputs(outdir, rows, info, args.debug, args.force)
    except FileExistsError as error:
        print(f"{OUTPUT_PREFIX}: error: {error}", file=sys.stderr)
        return 2
    for path in written:
        print(f"wrote {path}")
    return 0
