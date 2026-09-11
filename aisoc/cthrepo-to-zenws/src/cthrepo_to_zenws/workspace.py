"""Discover the zen workspace and resolve where a cheetah path belongs in it."""

from __future__ import annotations

import os
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

from cthrepo_to_zenws.migration import (
    CategoryRule,
    directory_map,
    parent_dir,
    parse_category_rules,
    parse_migration_report,
)


@dataclass(frozen=True)
class Candidate:
    path: str
    source: str


@dataclass(frozen=True)
class Resolution:
    path: str | None
    source: str


@dataclass
class ZenWorkspace:
    root: Path
    subrepos: list[str]
    dest_root: Path
    mapping: dict[str, str] = field(default_factory=dict)
    dir_map: dict[str, str] = field(default_factory=dict)
    category_rules: list[CategoryRule] = field(default_factory=list)
    basename_index: dict[str, list[str]] = field(default_factory=dict)

    def exists(self, rel_path: str) -> bool:
        return (self.dest_root / rel_path).is_file()

    def abs_path(self, rel_path: str) -> Path:
        return self.dest_root / rel_path


def discover_subrepos(root: Path) -> list[str]:
    return sorted(p.parent.name for p in root.glob("*/.git"))


def find_migration_report(root: Path) -> Path | None:
    return next(iter(sorted(root.glob("*/migration_report.txt"))), None)


def build_basename_index(dest_root: Path) -> dict[str, list[str]]:
    index: dict[str, list[str]] = defaultdict(list)
    for dirpath, dirnames, filenames in os.walk(dest_root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        rel_dir = os.path.relpath(dirpath, dest_root)
        prefix = "" if rel_dir == "." else rel_dir + "/"
        for name in filenames:
            index[name].append(prefix + name)
    return dict(index)


def load_workspace(root: Path, report_path: Path | None = None) -> ZenWorkspace:
    subrepos = discover_subrepos(root)
    report = report_path or find_migration_report(root)
    dest_root = report.parent if report else root
    text = report.read_text(encoding="utf-8", errors="replace") if report else ""
    mapping = parse_migration_report(text)
    return ZenWorkspace(
        root=root,
        subrepos=subrepos,
        dest_root=dest_root,
        mapping=mapping,
        dir_map=directory_map(mapping),
        category_rules=parse_category_rules(text),
        basename_index=build_basename_index(dest_root),
    )


def destination_candidates(ws: ZenWorkspace, path: str) -> list[Candidate]:
    """Every plausible destination for `path`, most trustworthy first."""
    out: list[Candidate] = []
    seen: set[str] = set()

    def add(candidate_path: str | None, source: str) -> None:
        if candidate_path and candidate_path not in seen:
            seen.add(candidate_path)
            out.append(Candidate(candidate_path, source))

    name = path.rsplit("/", 1)[-1]
    src_dir = parent_dir(path)

    add(ws.mapping.get(path), "migration-report")
    if ws.exists(path):
        add(path, "identity-path")

    sibling_dir = ws.dir_map.get(src_dir)
    if sibling_dir is not None:
        add(f"{sibling_dir}/{name}" if sibling_dir else name, "sibling-directory")

    for rule in ws.category_rules:
        mapped = rule.apply(path)
        if mapped:
            add(mapped, "category-rule")
            break

    if src_dir and (ws.dest_root / src_dir).is_dir():
        add(path, "identity-directory")

    matches = ws.basename_index.get(name, [])
    if len(matches) == 1:
        add(matches[0], "unique-basename")

    return out


def resolve_destination(ws: ZenWorkspace, path: str) -> Resolution:
    """Pick a destination, preferring a candidate that names a real file.

    Existence outranks trust order: a speculative category rule must not beat a
    lower-ranked candidate that actually points at the file in the workspace.
    """
    candidates = destination_candidates(ws, path)
    for candidate in candidates:
        if ws.exists(candidate.path):
            return Resolution(candidate.path, candidate.source)
    if candidates:
        return Resolution(candidates[0].path, candidates[0].source)
    return Resolution(None, "unresolved")
