#!/usr/bin/env python3
"""cthbind — Cheetah container bindings generator.

Scans an active Cheetah shell (via `cth_query`) and an existing aisoc
container bindings yaml, and produces an augmented copy of that yaml with
the directories required by the current Cheetah release added to its
`bindings_tools:` section.

See scripts/aisoc/cthbind.spec.md for the full specification.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import socket
import subprocess
import sys
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

CthQueryRunner = Callable[[str], subprocess.CompletedProcess]

# Well-known system directories excluded from bindings_tools candidates.
_NOISE_DIRS = {"/bin", "/usr/bin", "/usr/local/bin"}
_NOISE_PREFIXES = ("/usr/lib", "/lib")

# cth_query key/value separator: "key = value" or "key := value".
_KV_SEPARATOR = re.compile(r"\s*:=\s*|\s*=\s*")

# Collapses multiple consecutive slashes to one, as the filesystem would.
_MULTI_SLASH = re.compile(r"/{2,}")


def normalize_slashes(path: str) -> str:
    return _MULTI_SLASH.sub("/", path)


# --------------------------------------------------------------------------- #
# cth_query INI-ish output parsing
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class QueryRow:
    flow: str
    section: str
    key: str
    value: str


def parse_cth_query_output(text: str) -> list[tuple[str, str, str]]:
    """Parse `cth_query -tool <flow> -resolve` output into (section, key, value) rows.

    Section headers are case-insensitive and normalized to uppercase. Repeated
    [License] blocks are collapsed to their `Feature` key only (`Mode` and any
    other license keys are dropped here). Key/value pairs may be separated by
    `=` or `:=` (e.g. `default_python_version := 3.13.2`).
    """
    rows: list[tuple[str, str, str]] = []
    section: str | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            section = m.group(1).upper()
            continue
        if section is None:
            continue
        kv = _KV_SEPARATOR.search(line)
        if kv is None:
            continue
        key = line[: kv.start()].strip()
        value = line[kv.end() :].strip()
        if section == "LICENSE":
            if key.lower() == "feature":
                rows.append((section, key, value))
            continue
        rows.append((section, key, value))
    return rows


def rows_for_flow(flow: str, text: str) -> list[QueryRow]:
    """Parse `text` and dedup repeated LICENSE Feature rows for a single flow."""
    rows: list[QueryRow] = []
    seen_features: set[str] = set()
    for section, key, value in parse_cth_query_output(text):
        if section == "LICENSE":
            if value in seen_features:
                continue
            seen_features.add(value)
        rows.append(QueryRow(flow=flow, section=section, key=key, value=value))
    return rows


# --------------------------------------------------------------------------- #
# Directory detection / PATH splitting
# --------------------------------------------------------------------------- #
def is_noise_dir(path: str) -> bool:
    if path in _NOISE_DIRS:
        return True
    return any(path.startswith(prefix) for prefix in _NOISE_PREFIXES)


def existence_check_entries(value: str) -> list[str]:
    """Entries from `value` that should be checked for existence/readability."""
    if ":" in value:
        return [p for p in value.split(":") if p]
    if value.startswith("/"):
        return [value]
    return []


def bindings_candidates(value: str) -> list[str]:
    """Directory candidates for bindings_tools extracted from `value`."""
    entries = value.split(":") if ":" in value else [value]
    return [e for e in entries if e.startswith("/") and not is_noise_dir(e)]


# --------------------------------------------------------------------------- #
# Dedup & bindings_tools block rendering
# --------------------------------------------------------------------------- #
@dataclass
class BindingEntry:
    directory: str
    flows: list[str] = field(default_factory=list)
    comments: list[str] = field(default_factory=list)


def build_bindings_additions(rows: list[QueryRow]) -> list[BindingEntry]:
    """Dedup directory candidates across flows, preserving first-seen order."""
    order: list[str] = []
    by_dir: dict[str, BindingEntry] = {}
    for row in rows:
        for directory in bindings_candidates(row.value):
            entry = by_dir.get(directory)
            if entry is None:
                entry = BindingEntry(directory=directory, flows=[])
                by_dir[directory] = entry
                order.append(directory)
            if row.flow not in entry.flows:
                entry.flows.append(row.flow)
    return [by_dir[d] for d in order]


def render_addition_block(entries: list[BindingEntry]) -> list[str]:
    lines = ["  # Start cthbind additions"]
    for e in entries:
        lines.append(f"  # Registered by flows: {' '.join(e.flows)}")
        for comment in e.comments:
            lines.append(f"  # {comment}")
        lines.append(f'  - "{e.directory}"')
    lines.append("  # Finish cthbind additions")
    return lines


def insert_cthbind_block(original_text: str, block_lines: list[str]) -> str:
    """Append `block_lines` to the end of the `bindings_tools:` section."""
    lines = original_text.splitlines(keepends=True)
    start_idx = None
    for i, line in enumerate(lines):
        if line.strip() == "bindings_tools:":
            start_idx = i
            break
    if start_idx is None:
        raise ValueError("bindings_tools: section not found in input yaml")

    end_idx = len(lines)
    for i in range(start_idx + 1, len(lines)):
        if lines[i].strip() == "":
            continue
        if not lines[i][0].isspace():
            end_idx = i
            break

    prefix_lines = lines[:end_idx]
    if prefix_lines and not prefix_lines[-1].endswith("\n"):
        prefix_lines[-1] += "\n"
    insertion = "".join(f"{line}\n" for line in block_lines)
    return "".join(prefix_lines) + insertion + "".join(lines[end_idx:])


_YAML_LIST_ITEM_RE = re.compile(r"""^-\s*(?:"([^"]*)"|'([^']*)'|([^\s#]+))""")


def parse_existing_bindings_tools(original_text: str) -> set[str]:
    """Directories already listed in the original yaml's `bindings_tools:` section.

    Entries may be plain paths or Singularity `src:dest` bind syntax (quoted or not);
    only the source (left of the first `:`) is kept, normalized (multi-slash collapsed,
    trailing slash stripped) for comparison.
    """
    lines = original_text.splitlines()
    start_idx = None
    for i, line in enumerate(lines):
        if line.strip() == "bindings_tools:":
            start_idx = i
            break
    if start_idx is None:
        return set()

    existing: set[str] = set()
    for line in lines[start_idx + 1 :]:
        if line.strip() == "":
            continue
        if not line[0].isspace():
            break
        stripped = line.strip()
        if stripped.startswith("#") or not stripped.startswith("-"):
            continue
        m = _YAML_LIST_ITEM_RE.match(stripped)
        if not m:
            continue
        value = next(g for g in m.groups() if g is not None)
        source = value.split(":", 1)[0]
        existing.add(normalize_slashes(source).rstrip("/"))
    return existing


def filter_existing_in_yaml(
    entries: list[BindingEntry], existing: set[str]
) -> tuple[list[BindingEntry], list[FilteredEntry]]:
    """Drop directories already listed in the original yaml's `bindings_tools:` section."""
    kept: list[BindingEntry] = []
    filtered: list[FilteredEntry] = []
    for entry in entries:
        normalized = normalize_slashes(entry.directory).rstrip("/")
        if normalized in existing:
            filtered.append(
                FilteredEntry(
                    entry=entry, reason="already present in original yaml bindings_tools:"
                )
            )
            continue
        kept.append(entry)
    return kept, filtered


# --------------------------------------------------------------------------- #
# Readable-directory filtering (bug fix: exclude unresolved tokens / files)
# --------------------------------------------------------------------------- #
def is_readable_dir(path: str) -> bool:
    return os.path.isdir(path) and os.access(path, os.R_OK)


def partition_readable(
    entries: list[BindingEntry],
) -> tuple[list[BindingEntry], list[BindingEntry]]:
    """Split dedup'd candidates into (readable directories, missing/unreadable/non-dir).

    Only readable directories are added to bindings_tools; the rest (e.g.
    unresolved `toolversion(KEY)` tokens or plain files) are excluded here but
    still recorded in the CSV and reported as missing in the .log/.report.
    """
    accepted: list[BindingEntry] = []
    missing: list[BindingEntry] = []
    for entry in entries:
        (accepted if is_readable_dir(entry.directory) else missing).append(entry)
    return accepted, missing


# --------------------------------------------------------------------------- #
# Directory-tree reduction (.final)
# --------------------------------------------------------------------------- #
def digit_count(value: str) -> int:
    return sum(1 for c in value if c.isdigit())


def known_version_values(rows: list[QueryRow]) -> set[str]:
    """Version-like values from TOOLVERSION[/_<os>] and LITEINFRA rows.

    A value counts as version-like if it has at least 4 digit characters
    anywhere in it (digits need not be contiguous). Matching directory segments
    against these exact extracted values (rather than digit-counting path
    segments directly) avoids false positives like `x86-64_linux26`.
    """
    values: set[str] = set()
    for row in rows:
        if (
            row.section == "TOOLVERSION"
            or row.section.startswith("TOOLVERSION_")
            or row.section == "LITEINFRA"
        ):
            if digit_count(row.value) >= 4:
                values.add(row.value)
    return values


def version_floor(directory: str, known_versions: set[str]) -> str:
    """Truncate `directory` to end at its deepest segment matching a known version.

    Never truncates shallower than that segment; returns `directory` unchanged
    if no segment matches (safest default: no reduction target found).
    """
    segments = directory.split("/")
    deepest = None
    for i, seg in enumerate(segments):
        if seg in known_versions:
            deepest = i
    if deepest is None:
        return directory
    return "/".join(segments[: deepest + 1])


@dataclass
class ReductionGroup:
    floor: BindingEntry
    originals: list[BindingEntry]


def reduce_bindings_additions(
    entries: list[BindingEntry], known_versions: set[str]
) -> list[ReductionGroup]:
    """Collapse entries sharing a version floor into a single entry.

    Handles both spec examples uniformly: sibling directories under a common
    (not independently-required) version directory, and a version directory
    together with its own subdirectories. Directories are normalized (multiple
    consecutive slashes collapsed to one, as the filesystem would) before the
    floor is computed, so e.g. `.../rtla//X-2025.06-SP2` and
    `.../rtla/X-2025.06-SP2` merge into a single entry.
    """
    order: list[str] = []
    by_floor: dict[str, BindingEntry] = {}
    originals_by_floor: dict[str, list[BindingEntry]] = {}
    for entry in entries:
        normalized_dir = normalize_slashes(entry.directory)
        floor_dir = version_floor(normalized_dir, known_versions)
        target = by_floor.get(floor_dir)
        if target is None:
            target = BindingEntry(directory=floor_dir, flows=[])
            by_floor[floor_dir] = target
            originals_by_floor[floor_dir] = []
            order.append(floor_dir)
        for flow in entry.flows:
            if flow not in target.flows:
                target.flows.append(flow)
        originals_by_floor[floor_dir].append(entry)
    return [ReductionGroup(floor=by_floor[f], originals=originals_by_floor[f]) for f in order]


# --------------------------------------------------------------------------- #
# Generic-directory filter (post-reduction; .final only)
# --------------------------------------------------------------------------- #
_EDA_VERSIONED_ROOT_RE = re.compile(r"^/p/hdk/rtl/cad/x86-64_linux[^/]*(?:/|$)")
_EDA_CAD_ROOT = "/p/hdk/cad/"
_EDA_PROJ_TOOLS_ROOT = "/p/hdk/rtl/proj_tools/"
MIN_DEPTH_LEVELS = 4
MIN_VERSION_BASENAME_DIGITS = 2


def path_segments(directory: str) -> list[str]:
    """Non-empty path segments; robust to multiple/trailing slashes."""
    return [seg for seg in normalize_slashes(directory).rstrip("/").split("/") if seg]


def is_too_shallow(directory: str, min_levels: int = MIN_DEPTH_LEVELS) -> bool:
    """True if `directory` has `min_levels` or fewer path segments (e.g. `/p/hdk/cad/conformal`)."""
    return len(path_segments(directory)) <= min_levels


def requires_version_basename(directory: str) -> bool:
    """True if `directory` is under an EDA tool release root that must end in a version."""
    normalized = normalize_slashes(directory)
    return (
        bool(_EDA_VERSIONED_ROOT_RE.match(normalized))
        or normalized.startswith(_EDA_CAD_ROOT)
        or normalized.startswith(_EDA_PROJ_TOOLS_ROOT)
    )


def has_version_like_basename(directory: str, min_digits: int = MIN_VERSION_BASENAME_DIGITS) -> bool:
    segments = path_segments(directory)
    return bool(segments) and digit_count(segments[-1]) >= min_digits


@dataclass
class FilteredEntry:
    entry: BindingEntry
    reason: str


def filter_generic_directories(
    entries: list[BindingEntry],
) -> tuple[list[BindingEntry], list[FilteredEntry]]:
    """Drop existing/readable directories judged too generic to bind.

    Rule 1 (applied first): directories with `MIN_DEPTH_LEVELS` or fewer path
    segments are dropped (e.g. `/p/hdk/cad/conformal`, but not
    `/p/hdk/cad/conformal/25.20-p100`).
    Rule 2: directories under an EDA tool release root (`/p/hdk/rtl/cad/x86-64_linux*`,
    `/p/hdk/cad/`, or `/p/hdk/rtl/proj_tools/`) are dropped unless their final path segment
    looks like a version (>= `MIN_VERSION_BASENAME_DIGITS` digit characters, not necessarily
    contiguous), e.g. `.../mentor/visualizer` is dropped but
    `.../mentor/visualizer/w230217` is kept.
    """
    kept: list[BindingEntry] = []
    filtered: list[FilteredEntry] = []
    for entry in entries:
        if is_too_shallow(entry.directory):
            filtered.append(FilteredEntry(entry=entry, reason="too shallow (<=4 levels deep)"))
            continue
        if requires_version_basename(entry.directory) and not has_version_like_basename(
            entry.directory
        ):
            filtered.append(
                FilteredEntry(entry=entry, reason="EDA tool root without a version basename")
            )
            continue
        kept.append(entry)
    return kept, filtered


# --------------------------------------------------------------------------- #
# User-supplied --filter regex file (post-reduction; .final only)
# --------------------------------------------------------------------------- #
def parse_filter_file(path: Path) -> list[re.Pattern[str]]:
    r"""Parse a --filter file: one `"<regexp>"` per line, `#` comments, blank lines ignored.

    The quoted text is compiled as-is via `re.compile` (fed into `re.search`); no unescaping
    is needed since `\/` etc. are already valid regex syntax for a literal character.
    """
    patterns: list[re.Pattern[str]] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if len(line) < 2 or not (line.startswith('"') and line.endswith('"')):
            raise ValueError(f'invalid --filter line (expected "regexp"): {raw_line!r}')
        patterns.append(re.compile(line[1:-1]))
    return patterns


def apply_user_filter(
    entries: list[BindingEntry], patterns: list[re.Pattern[str]]
) -> tuple[list[BindingEntry], list[FilteredEntry]]:
    """Drop directories matching any --filter pattern (re.search, first match wins)."""
    if not patterns:
        return entries, []
    kept: list[BindingEntry] = []
    filtered: list[FilteredEntry] = []
    for entry in entries:
        matched = next((p for p in patterns if p.search(entry.directory)), None)
        if matched is None:
            kept.append(entry)
            continue
        filtered.append(
            FilteredEntry(entry=entry, reason=f'--filter pattern matched: "{matched.pattern}"')
        )
    return kept, filtered


# --------------------------------------------------------------------------- #
# User-supplied --include file (processed last, after reduction & all filtering)
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class IncludeEntry:
    directory: str
    comments: list[str]


def parse_include_file(path: Path) -> list[IncludeEntry]:
    """Parse a --include file: one directory per line, `#` comments, blank lines ignored.

    Comment lines accumulate (blank lines don't reset them) and attach to the next
    directory line encountered; the accumulator then resets, so a comment block only
    carries over to the single directory that follows it.
    """
    entries: list[IncludeEntry] = []
    pending_comments: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            pending_comments.append(line[1:].strip())
            continue
        entries.append(IncludeEntry(directory=line, comments=pending_comments))
        pending_comments = []
    return entries


@dataclass
class IncludeResult:
    directory: str
    added: bool


def add_includes(
    entries: list[BindingEntry], include_entries: list[IncludeEntry]
) -> tuple[list[BindingEntry], list[IncludeResult]]:
    """Append --include directories (tagged `--include`) last, after reduction/filtering.

    A directory already present in `entries` is not duplicated, but is still reported
    (as skipped) in file order. Duplicate lines within the include file itself are
    likewise only processed once. Any comments carried with a duplicate are simply
    dropped along with it.
    """
    existing = {e.directory for e in entries}
    combined = list(entries)
    results: list[IncludeResult] = []
    seen: set[str] = set()
    for inc in include_entries:
        if inc.directory in seen:
            continue
        seen.add(inc.directory)
        if inc.directory in existing:
            results.append(IncludeResult(directory=inc.directory, added=False))
            continue
        combined.append(
            BindingEntry(directory=inc.directory, flows=["--include"], comments=inc.comments)
        )
        existing.add(inc.directory)
        results.append(IncludeResult(directory=inc.directory, added=True))
    return combined, results


# --------------------------------------------------------------------------- #
# Activity mapping file
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class ActivityEntry:
    flow: str
    activity: str


def parse_activity_mapping(path: Path) -> list[ActivityEntry]:
    entries: list[ActivityEntry] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        entries.append(ActivityEntry(flow=parts[0], activity=parts[1]))
    return entries


def resolve_activity_mapping_path(mapping_env: str, workarea: Path) -> Path:
    p = Path(mapping_env)
    if not p.is_absolute():
        p = workarea / p
    return p


# --------------------------------------------------------------------------- #
# cth_query invocation
# --------------------------------------------------------------------------- #
GLOBAL_FLOW = "GLOBAL"
GLOBAL_ACTIVITY = "n/a"


def default_cth_query_runner(flow: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["cth_query", "-tool", flow, "-resolve"],
        capture_output=True,
        text=True,
        check=False,
    )


def default_global_cth_query_runner(_flow: str) -> subprocess.CompletedProcess:
    """Runs `cth_query -resolve` with no `-tool`, once per cthbind run.

    Captures environment-wide state not tied to any single flow, notably the
    [LITEINFRA] section.
    """
    return subprocess.run(
        ["cth_query", "-resolve"],
        capture_output=True,
        text=True,
        check=False,
    )


@dataclass
class FlowResult:
    flow: str
    activity: str
    ok: bool
    error: str | None
    raw_output: str
    rows: list[QueryRow]


def process_flow(flow: str, activity: str, runner: CthQueryRunner) -> FlowResult:
    try:
        proc = runner(flow)
    except OSError as exc:
        return FlowResult(flow, activity, False, str(exc), "", [])
    if proc.returncode != 0 or not proc.stdout.strip():
        error = proc.stderr.strip() or f"cth_query exited {proc.returncode} with empty output"
        return FlowResult(flow, activity, False, error, proc.stdout, [])
    rows = rows_for_flow(flow, proc.stdout)
    return FlowResult(flow, activity, True, None, proc.stdout, rows)


# --------------------------------------------------------------------------- #
# CSV output
# --------------------------------------------------------------------------- #
def write_csv(path: Path, flow_results: list[FlowResult]) -> None:
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["flow", "section", "key", "value"])
        for fr in flow_results:
            if not fr.ok:
                continue
            for row in fr.rows:
                writer.writerow([row.flow, row.section, row.key, row.value])


# --------------------------------------------------------------------------- #
# Log output (written incrementally: header at start, body per flow processed)
# --------------------------------------------------------------------------- #
def build_log_header(command_line: str, start_time: float, debug_level: int) -> str:
    lines = [
        f"Command: {command_line}",
        f"Start: {datetime.fromtimestamp(start_time).isoformat()}",
        f"Epoch: {start_time}",
        f"Host: {socket.gethostname()}",
        f"CWD: {os.getcwd()}",
    ]
    if debug_level > 0:
        lines.append(f"-D- Debug level {debug_level} enabled")
    lines.append("")
    return "\n".join(lines) + "\n"


def build_log_flow_block(fr: FlowResult, debug_level: int) -> str:
    lines = [f"Flow: {fr.flow} ({fr.activity})"]
    if not fr.ok:
        lines.append(f"  -E- cth_query failed: {fr.error}")
        lines.append("")
        return "\n".join(lines) + "\n"

    lines.append(f"  Rows extracted: {len(fr.rows)}")
    missing: list[tuple[QueryRow, str]] = []
    for row in fr.rows:
        for entry in existence_check_entries(row.value):
            if not (os.path.isdir(entry) and os.access(entry, os.R_OK)):
                missing.append((row, entry))
    for row, entry in missing:
        lines.append(
            f"  -W- missing/unreadable: flow={row.flow} section={row.section} "
            f"key={row.key} path={entry}"
        )

    if debug_level >= 5:
        lines.append("  -D- raw cth_query output:")
        for raw_line in fr.raw_output.splitlines():
            lines.append(f"    {raw_line}")
        lines.append("  -D- parsed rows:")
        for row in fr.rows:
            lines.append(f"    {row.section}\t{row.key}\t{row.value}")

    lines.append(f"  Flow complete. Missing/unreadable paths: {len(missing)}")
    lines.append("")
    return "\n".join(lines) + "\n"


def write_log_header(log_path: Path, command_line: str, start_time: float, debug_level: int) -> None:
    log_path.write_text(build_log_header(command_line, start_time, debug_level), encoding="utf-8")


def append_log_flow(log_path: Path, fr: FlowResult, debug_level: int) -> None:
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(build_log_flow_block(fr, debug_level))


# --------------------------------------------------------------------------- #
# Human-readable report (.cthbind.report)
# --------------------------------------------------------------------------- #
def render_missing_directories_section(missing: list[BindingEntry]) -> list[str]:
    lines = ["# Summary of missing directories"]
    for entry in sorted(missing, key=lambda e: e.directory):
        lines.append(f"# Registered by flows: {' '.join(entry.flows)}")
        lines.append(entry.directory)
    return lines


def render_duplicate_toolversions_section(rows: list[QueryRow]) -> list[str]:
    by_key: dict[str, dict[str, list[str]]] = {}
    key_order: list[str] = []
    for row in rows:
        if row.section != "TOOLVERSION":
            continue
        if row.key not in key_order:
            key_order.append(row.key)
        flows = by_key.setdefault(row.key, {}).setdefault(row.value, [])
        if row.flow not in flows:
            flows.append(row.flow)

    duplicate_keys = [k for k in key_order if len(by_key[k]) > 1]

    lines = [
        "# Summary of duplicate toolversions",
        f"# Total unique keys with at least one duplicate value: {len(duplicate_keys)}",
        "",
        "# Unique keys with duplicate values:",
    ]
    for key in duplicate_keys:
        lines.append(f"{key}\tTotal Unique Values: {len(by_key[key])}")
    lines.append("")

    for key in duplicate_keys:
        values = by_key[key]
        lines.append(
            f"# TOOLVERSION key: {key}\tTotal Unique Values for this TOOLVERSION: {len(values)}"
        )
        for value, flows in values.items():
            lines.append(f"# Registered by flows: {' '.join(flows)}")
            lines.append(f"{key}={value}")
        lines.append("")

    return lines


def render_reduction_summary_section(groups: list[ReductionGroup]) -> list[str]:
    lines = ["# Summary of directory reductions for .final file"]
    changed = [
        g for g in groups if len(g.originals) > 1 or g.originals[0].directory != g.floor.directory
    ]
    for g in changed:
        lines.append("")
        lines.append("Group Before reduction:")
        for orig in g.originals:
            lines.append(f"  # Registered by flows: {' '.join(orig.flows)}")
            lines.append(f'  - "{orig.directory}"')
        lines.append("")
        lines.append("Group After reduction:")
        lines.append(f"  # Registered by flows: {' '.join(g.floor.flows)}")
        lines.append(f'  - "{g.floor.directory}"')
    return lines


def render_generic_filter_section(filtered: list[FilteredEntry]) -> list[str]:
    lines = ["# Summary of directories filtered from .final (generic / versionless)"]
    for fe in sorted(filtered, key=lambda f: f.entry.directory):
        lines.append(f"# Registered by flows: {' '.join(fe.entry.flows)}")
        lines.append(f"# Reason: {fe.reason}")
        lines.append(fe.entry.directory)
    return lines


def render_include_section(results: list[IncludeResult]) -> list[str]:
    lines = ["# Summary of directories added via --include"]
    for r in results:
        status = "added" if r.added else "skipped (already present in .final)"
        lines.append(f"# Status: {status}")
        lines.append(r.directory)
    return lines


@dataclass(frozen=True)
class RunCounts:
    found: int
    found_readable: int
    grouped: int
    after_filtering: int
    include_total: int
    include_readable: int
    final_total: int
    final_path: Path


def render_counts_section(counts: RunCounts) -> list[str]:
    return [
        "# Summary of counts",
        f"Total directories found in cth_query registry (deduplicated): {counts.found}",
        f"Total readable directories found in cth_query registry: {counts.found_readable}",
        f"Total readable directories after grouping: {counts.grouped}",
        f"Total readable directories after filtering: {counts.after_filtering}",
        f"Total directories provided in --includes: {counts.include_total}",
        f"Total readable directories provided in --includes: {counts.include_readable}",
        f"Final bindings added to output yaml: {counts.final_total}",
        f"Output yaml: {counts.final_path}",
    ]


def build_report(
    counts: RunCounts,
    missing: list[BindingEntry],
    all_rows: list[QueryRow],
    reduction_groups: list[ReductionGroup],
    filtered_generic: list[FilteredEntry],
    include_results: list[IncludeResult],
) -> str:
    lines: list[str] = []
    lines.extend(render_counts_section(counts))
    lines.append("")
    lines.extend(render_missing_directories_section(missing))
    lines.append("")
    lines.extend(render_duplicate_toolversions_section(all_rows))
    lines.append("")
    lines.extend(render_reduction_summary_section(reduction_groups))
    lines.append("")
    lines.extend(render_generic_filter_section(filtered_generic))
    lines.append("")
    lines.extend(render_include_section(include_results))
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- #
# Pre-flight validation
# --------------------------------------------------------------------------- #
def validate_environment(
    workarea: Path | None,
    input_yaml: Path,
    filter_path: Path | None = None,
    include_path: Path | None = None,
) -> list[str]:
    errors: list[str] = []
    if workarea is None:
        errors.append("$WORKAREA is not set and --workarea not given.")
    elif not workarea.is_dir():
        errors.append(f"WORKAREA is not a valid directory: {workarea}")

    if not os.environ.get("CTH_SETUP_CMD"):
        errors.append("$CTH_SETUP_CMD is not set.")

    mapping_env = os.environ.get("FE_ACTIVITY_MAPPING")
    if not mapping_env:
        errors.append("$FE_ACTIVITY_MAPPING is not set.")
    elif workarea is not None:
        mapping_path = resolve_activity_mapping_path(mapping_env, workarea)
        if not mapping_path.is_file():
            errors.append(f"FE_ACTIVITY_MAPPING file not found: {mapping_path}")

    if not (input_yaml.is_file() and os.access(input_yaml, os.R_OK)):
        errors.append(f"Input yaml not found or not readable: {input_yaml}")

    if filter_path is not None and not (filter_path.is_file() and os.access(filter_path, os.R_OK)):
        errors.append(f"--filter file not found or not readable: {filter_path}")

    if include_path is not None:
        if not (include_path.is_file() and os.access(include_path, os.R_OK)):
            errors.append(f"--include file not found or not readable: {include_path}")
        else:
            for inc in parse_include_file(include_path):
                if not is_readable_dir(inc.directory):
                    errors.append(
                        f"--include directory not found or not readable: {inc.directory}"
                    )

    return errors


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="cthbind.py",
        description="Generate an augmented aisoc container bindings yaml for the current Cheetah release.",
    )
    parser.add_argument(
        "--workarea", type=Path, default=None, help="Work area root (default: $WORKAREA)."
    )
    parser.add_argument(
        "--input-yaml", type=Path, required=True, help="Input container bindings yaml."
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Print the planned actions/paths; write nothing."
    )
    parser.add_argument(
        "--verbose", action="store_true", help="Print more information, including per-flow summary counts."
    )
    parser.add_argument(
        "--debug",
        type=int,
        default=0,
        choices=range(0, 6),
        metavar="LEVEL",
        help="Debug detail level (1-5) written to the log file.",
    )
    parser.add_argument(
        "--filter",
        type=Path,
        default=None,
        help=(
            'Optional file of exclusion patterns, one "<regexp>" per line (\'#\' comments and '
            "blank lines ignored). Applied to .final only, after all other filtering: a "
            "directory is dropped if any pattern matches (re.search) its path."
        ),
    )
    parser.add_argument(
        "--include",
        type=Path,
        default=None,
        help=(
            "Optional file listing extra directories to add to .final, one per line "
            "('#' comments and blank lines ignored). Every directory must exist and be "
            "readable (checked pre-flight). Processed last, after reduction and all "
            "filtering/--filter."
        ),
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)

    env_workarea = os.environ.get("WORKAREA")
    workarea = (args.workarea or (Path(env_workarea) if env_workarea else None))
    if workarea is not None:
        workarea = workarea.resolve()
    input_yaml = args.input_yaml.resolve()
    filter_path = args.filter.resolve() if args.filter else None
    include_path = args.include.resolve() if args.include else None

    errors = validate_environment(workarea, input_yaml, filter_path, include_path)
    if errors:
        for e in errors:
            print(f"-E- {e}", file=sys.stderr)
        return 2
    assert workarea is not None

    filter_patterns = parse_filter_file(filter_path) if filter_path else []
    include_entries = parse_include_file(include_path) if include_path else []

    mapping_path = resolve_activity_mapping_path(os.environ["FE_ACTIVITY_MAPPING"], workarea)
    activities = parse_activity_mapping(mapping_path)

    basename = input_yaml.name
    orig_path = workarea / f"{basename}.cthbind.orig"
    raw_path = workarea / f"{basename}.cthbind.raw"
    final_path = workarea / f"{basename}.cthbind.final"
    csv_path = workarea / f"{basename}.cthbind.csv"
    log_path = workarea / f"{basename}.cthbind.log"
    report_path = workarea / f"{basename}.cthbind.report"

    command_line = "cthbind.py " + " ".join(argv if argv is not None else sys.argv[1:])
    start_time = time.time()
    if not args.dry_run:
        write_log_header(log_path, command_line, start_time, args.debug)

    flow_results: list[FlowResult] = []

    # Single no-args `cth_query -resolve` call (not tied to any flow), run once
    # up front; captures env-wide state such as [LITEINFRA].
    global_result = process_flow(GLOBAL_FLOW, GLOBAL_ACTIVITY, default_global_cth_query_runner)
    flow_results.append(global_result)
    if not args.dry_run:
        append_log_flow(log_path, global_result, args.debug)

    for entry in activities:
        fr = process_flow(entry.flow, entry.activity, default_cth_query_runner)
        flow_results.append(fr)
        if not args.dry_run:
            append_log_flow(log_path, fr, args.debug)

    all_rows = [row for fr in flow_results for row in fr.rows]
    all_additions = build_bindings_additions(all_rows)
    accepted, missing = partition_readable(all_additions)
    known_versions = known_version_values(all_rows)
    reduction_groups = reduce_bindings_additions(accepted, known_versions)
    grouped_additions = [g.floor for g in reduction_groups]
    final_additions, filtered_generic = filter_generic_directories(grouped_additions)

    original_text = input_yaml.read_text(encoding="utf-8")
    existing_bindings = parse_existing_bindings_tools(original_text)
    final_additions, filtered_existing = filter_existing_in_yaml(
        final_additions, existing_bindings
    )
    final_additions, filtered_by_user = apply_user_filter(final_additions, filter_patterns)
    all_filtered = filtered_generic + filtered_existing + filtered_by_user
    after_filtering_count = len(final_additions)
    final_additions, include_results = add_includes(final_additions, include_entries)

    raw_text = insert_cthbind_block(original_text, render_addition_block(accepted))
    final_text = insert_cthbind_block(original_text, render_addition_block(final_additions))
    counts = RunCounts(
        found=len(all_additions),
        found_readable=len(accepted),
        grouped=len(grouped_additions),
        after_filtering=after_filtering_count,
        include_total=len(include_entries),
        include_readable=sum(1 for e in include_entries if is_readable_dir(e.directory)),
        final_total=len(final_additions),
        final_path=final_path,
    )
    report_text = build_report(counts, missing, all_rows, reduction_groups, all_filtered, include_results)

    failed = [fr for fr in flow_results if not fr.ok]

    if args.dry_run:
        print("-I- Dry run; planned outputs:")
        for p in (orig_path, raw_path, final_path, csv_path, log_path, report_path):
            print(f"  {p}")
        if args.verbose:
            for fr in flow_results:
                status = "ok" if fr.ok else f"FAILED: {fr.error}"
                print(f"  flow={fr.flow} activity={fr.activity} rows={len(fr.rows)} status={status}")
            print(
                f"  bindings_tools additions: {len(accepted)} "
                f"(grouped: {counts.grouped}, missing: {len(missing)}, "
                f"filtered: {len(all_filtered)}, "
                f"included: {sum(1 for r in include_results if r.added)}, "
                f"final: {counts.final_total})"
            )
        return 1 if failed else 0

    shutil.copyfile(input_yaml, orig_path)
    raw_path.write_text(raw_text, encoding="utf-8")
    final_path.write_text(final_text, encoding="utf-8")
    write_csv(csv_path, flow_results)
    report_path.write_text(report_text, encoding="utf-8")

    if args.verbose:
        for fr in flow_results:
            status = "ok" if fr.ok else f"FAILED: {fr.error}"
            print(f"flow={fr.flow} activity={fr.activity} rows={len(fr.rows)} status={status}")
        print(
            f"bindings_tools additions: {len(accepted)} "
            f"(grouped: {counts.grouped}, missing: {len(missing)}, "
            f"filtered: {len(all_filtered)}, "
            f"included: {sum(1 for r in include_results if r.added)}, "
            f"final: {counts.final_total})"
        )

    if failed:
        for fr in failed:
            print(f"-E- flow {fr.flow}: {fr.error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
