"""Turn diff entries into an ordered, bucketed graft plan."""

from __future__ import annotations

import fnmatch
from dataclasses import dataclass
from pathlib import Path

from cthrepo_to_zenws.content import change_shape
from cthrepo_to_zenws.gitdiff import CHANGE_WORD, Change, blob_at
from cthrepo_to_zenws.workspace import ZenWorkspace, resolve_destination

BUCKET_AUTO_ADD = "auto-add"
BUCKET_AUTO_UPDATE = "auto-update"
BUCKET_AUTO_DELETE = "auto-delete"
BUCKET_AUTO_RENAME = "auto-rename"
BUCKET_REVIEW_ADD = "review-add-inferred-path"
BUCKET_REVIEW_COMMENT_ONLY = "review-comment-only"
BUCKET_REVIEW_WHITESPACE_ONLY = "review-whitespace-only"
BUCKET_REVIEW_DELETE = "review-delete"
BUCKET_MANUAL_MERGE = "manual-merge"
BUCKET_MANUAL_RENAME = "manual-rename"
BUCKET_MANUAL_LOCATE = "manual-locate-destination"
BUCKET_SKIP_UP_TO_DATE = "skip-up-to-date"
BUCKET_SKIP_IGNORED = "skip-ignored"
BUCKET_SKIP_NOT_MIGRATED = "skip-not-migrated"

AUTO_BUCKETS = (BUCKET_AUTO_ADD, BUCKET_AUTO_UPDATE, BUCKET_AUTO_DELETE, BUCKET_AUTO_RENAME)
NO_ACTION_BUCKETS = (BUCKET_SKIP_UP_TO_DATE, BUCKET_SKIP_IGNORED, BUCKET_SKIP_NOT_MIGRATED)

BUCKET_ORDER = (
    BUCKET_AUTO_ADD,
    BUCKET_AUTO_UPDATE,
    BUCKET_AUTO_DELETE,
    BUCKET_AUTO_RENAME,
    BUCKET_REVIEW_ADD,
    BUCKET_REVIEW_COMMENT_ONLY,
    BUCKET_REVIEW_WHITESPACE_ONLY,
    BUCKET_REVIEW_DELETE,
    BUCKET_MANUAL_MERGE,
    BUCKET_MANUAL_RENAME,
    BUCKET_MANUAL_LOCATE,
    BUCKET_SKIP_UP_TO_DATE,
    BUCKET_SKIP_IGNORED,
    BUCKET_SKIP_NOT_MIGRATED,
)


@dataclass(frozen=True)
class PlanRow:
    filename: str
    cheetah_path: str
    change: str
    bucket: str
    zen_path: str | None
    notes: str
    resolution: str = "unresolved"
    old_zen_path: str | None = None

    def csv_zen_path(self) -> str:
        return "" if self.bucket in NO_ACTION_BUCKETS else (self.zen_path or "")


def parse_pattern_file(path: Path) -> list[str]:
    patterns: list[str] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            patterns.append(stripped)
    return patterns


def matches_any(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def _row(
    change: Change,
    bucket: str,
    zen_path: str | None,
    notes: str,
    resolution: str = "unresolved",
    old_zen_path: str | None = None,
) -> PlanRow:
    return PlanRow(
        filename=change.path.rsplit("/", 1)[-1],
        cheetah_path=change.path,
        change=CHANGE_WORD[change.status],
        bucket=bucket,
        zen_path=zen_path,
        notes=notes,
        resolution=resolution,
        old_zen_path=old_zen_path,
    )


def plan_modify(
    change: Change, ws: ZenWorkspace, repo: Path, base_tag: str, head_tag: str
) -> PlanRow:
    resolution = resolve_destination(ws, change.path)
    rule = resolution.source
    if resolution.path is None:
        return _row(change, BUCKET_MANUAL_LOCATE, None, "no destination candidate", rule)

    if not ws.exists(resolution.path):
        return _row(
            change, BUCKET_MANUAL_LOCATE, resolution.path, "destination file missing", rule
        )

    base = blob_at(repo, base_tag, change.path) or b""
    head = blob_at(repo, head_tag, change.path) or b""
    current = ws.abs_path(resolution.path).read_bytes()

    if current == head:
        return _row(change, BUCKET_SKIP_UP_TO_DATE, resolution.path, "already matches head", rule)

    shape = change_shape(change.path, base, head)
    if current != base:
        return _row(
            change,
            BUCKET_MANUAL_MERGE,
            resolution.path,
            f"zen copy diverged from {base_tag}; {shape} change upstream",
            rule,
        )

    if shape == "whitespace":
        return _row(
            change, BUCKET_REVIEW_WHITESPACE_ONLY, resolution.path, "whitespace-only change", rule
        )
    if shape == "comment":
        return _row(
            change, BUCKET_REVIEW_COMMENT_ONLY, resolution.path, "comment-only change", rule
        )
    return _row(
        change, BUCKET_AUTO_UPDATE, resolution.path, f"zen copy matches {base_tag}", rule
    )


def plan_add(change: Change, ws: ZenWorkspace) -> PlanRow:
    resolution = resolve_destination(ws, change.path)
    rule = resolution.source
    if resolution.path is None:
        return _row(change, BUCKET_MANUAL_LOCATE, None, "no destination candidate", rule)
    if ws.exists(resolution.path):
        return _row(
            change, BUCKET_MANUAL_MERGE, resolution.path, "destination already exists", rule
        )
    if rule in ("migration-report", "sibling-directory"):
        return _row(change, BUCKET_AUTO_ADD, resolution.path, "trusted destination", rule)
    return _row(change, BUCKET_REVIEW_ADD, resolution.path, "destination inferred", rule)


def plan_delete(change: Change, ws: ZenWorkspace, repo: Path, base_tag: str) -> PlanRow:
    resolution = resolve_destination(ws, change.path)
    rule = resolution.source
    if resolution.path is None or not ws.exists(resolution.path):
        return _row(
            change, BUCKET_SKIP_NOT_MIGRATED, resolution.path, "not present in workspace", rule
        )
    base = blob_at(repo, base_tag, change.path) or b""
    current = ws.abs_path(resolution.path).read_bytes()
    if current == base:
        return _row(
            change, BUCKET_AUTO_DELETE, resolution.path, f"zen copy matches {base_tag}", rule
        )
    return _row(change, BUCKET_REVIEW_DELETE, resolution.path, "zen copy has local changes", rule)


def plan_rename(
    change: Change, ws: ZenWorkspace, repo: Path, base_tag: str, head_tag: str
) -> PlanRow:
    """A rename is only automated when the old copy is untouched and the new slot is free."""
    old_path = change.old_path or ""
    old_res = resolve_destination(ws, old_path)
    new_res = resolve_destination(ws, change.path)
    rule = new_res.source
    similarity = f"{change.similarity}%" if change.similarity is not None else "unknown"

    if old_res.path is None or not ws.exists(old_res.path):
        # The source was never migrated, so there is nothing to move; treat it as an add.
        row = plan_add(change, ws)
        return _row(
            change, row.bucket, row.zen_path, f"source never migrated; {row.notes}", rule
        )

    old_base = blob_at(repo, base_tag, old_path) or b""
    if ws.abs_path(old_res.path).read_bytes() != old_base:
        return _row(
            change,
            BUCKET_MANUAL_RENAME,
            new_res.path,
            f"{similarity} similar; zen copy of {old_res.path} diverged from {base_tag}",
            rule,
            old_res.path,
        )

    if new_res.path is None:
        return _row(
            change,
            BUCKET_MANUAL_RENAME,
            None,
            "no destination for the new path",
            rule,
            old_res.path,
        )

    if ws.exists(new_res.path) and new_res.path != old_res.path:
        return _row(
            change,
            BUCKET_MANUAL_MERGE,
            new_res.path,
            f"{similarity} similar; rename destination already exists",
            rule,
            old_res.path,
        )

    return _row(
        change,
        BUCKET_AUTO_RENAME,
        new_res.path,
        f"{similarity} similar; zen copy matches {base_tag}",
        rule,
        old_res.path,
    )


def build_plan(
    changes: list[Change],
    ws: ZenWorkspace,
    repo: Path,
    base_tag: str,
    head_tag: str,
    ignore: list[str] | None = None,
) -> list[PlanRow]:
    ignore = ignore or []
    rows: list[PlanRow] = []
    for change in changes:
        if matches_any(change.path, ignore):
            rows.append(
                _row(change, BUCKET_SKIP_IGNORED, None, "matched --ignore pattern", "not-resolved")
            )
        elif change.status == "M":
            rows.append(plan_modify(change, ws, repo, base_tag, head_tag))
        elif change.status == "A":
            rows.append(plan_add(change, ws))
        elif change.status == "R":
            rows.append(plan_rename(change, ws, repo, base_tag, head_tag))
        else:
            rows.append(plan_delete(change, ws, repo, base_tag))
    rows.sort(key=lambda r: (BUCKET_ORDER.index(r.bucket), r.cheetah_path))
    return rows
