"""git plumbing: the tag-to-tag diff that defines the whole scope of work."""

from __future__ import annotations

import io
import subprocess
import tarfile
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

# Plain --name-status: git's default rename detection is left on, so a rename
# arrives as a single R<similarity> row carrying both endpoints.
DIFF_ARGS = ["--name-status"]

CHANGE_WORD = {"A": "add", "M": "modify", "D": "delete", "R": "rename"}


class GitError(RuntimeError):
    pass


@dataclass(frozen=True)
class Change:
    status: str  # A, M, D or R
    path: str
    old_path: str | None = None
    similarity: int | None = None


def git_run(repo: Path, args: list[str], binary: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=not binary,
        check=False,
    )


def is_git_repo(repo: Path) -> bool:
    return git_run(repo, ["rev-parse", "--git-dir"]).returncode == 0


def rev_exists(repo: Path, rev: str) -> bool:
    return git_run(repo, ["rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}"]).returncode == 0


def blob_at(repo: Path, rev: str, path: str) -> bytes | None:
    """Contents of `path` at `rev`, or None if it does not exist there."""
    proc = git_run(repo, ["show", f"{rev}:{path}"], binary=True)
    return proc.stdout if proc.returncode == 0 else None


def extract_tree(repo: Path, rev: str, paths: Sequence[str], dest: Path) -> int:
    """Materialise `paths` at `rev` under `dest` so GUI tools get real files to open."""
    wanted = sorted(set(paths))
    if not wanted:
        return 0
    dest.mkdir(parents=True, exist_ok=True)
    proc = git_run(repo, ["archive", "--format=tar", rev, "--", *wanted], binary=True)
    if proc.returncode != 0:
        raise GitError(f"git archive {rev} failed: {proc.stderr.decode(errors='replace').strip()}")
    with tarfile.open(fileobj=io.BytesIO(proc.stdout)) as tar:
        tar.extractall(dest, filter="data")
    return len(wanted)


def parse_name_status(text: str) -> list[Change]:
    """Parse `git diff --name-status` output into Change records."""
    changes: list[Change] = []
    for raw_line in text.splitlines():
        if not raw_line.strip():
            continue
        fields = raw_line.split("\t")
        if len(fields) < 2:
            continue
        code = fields[0].strip()
        letter = code[0].upper()
        # A type change behaves like a modify for grafting purposes.
        letter = "M" if letter == "T" else letter
        if letter == "R" and len(fields) >= 3:
            similarity = int(code[1:]) if code[1:].isdigit() else None
            changes.append(
                Change(status="R", path=fields[2], old_path=fields[1], similarity=similarity)
            )
        elif letter in CHANGE_WORD and letter != "R":
            changes.append(Change(status=letter, path=fields[1]))
    return changes


def diff_command(base_tag: str, head_tag: str) -> list[str]:
    return ["diff", base_tag, head_tag, *DIFF_ARGS]


def diff_changes(repo: Path, base_tag: str, head_tag: str) -> list[Change]:
    args = diff_command(base_tag, head_tag)
    proc = git_run(repo, args)
    if proc.returncode != 0:
        raise GitError(f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return parse_name_status(proc.stdout)
