"""Shared fixtures: a real cheetah git repo plus a matching zen workspace."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

import pytest

from cthrepo_to_zenws.workspace import ZenWorkspace, load_workspace

RULES_TEXT = """
--- RTL CATEGORY MAPPING ---
  src/rtl/bridges/<block>/ -> BLOCKS/bridges/<block>/design/rtl/  [dual-role DUT]
  src/rtl/common/<block>/  -> COMMON/<block>/design/rtl/          [never DUT]
  src/rtl/pkg/             -> COMMON/pkg/design/rtl/<subpath>

--- VAL PASS-THROUGH MAPPING ---
  src/val/fv/       -> COMMON/fv/  (as-is)
  src/val/vip/      -> COMMON/vip/ (multi-DUT files only)
  src/val/vip/      -> TOP/<DUT>/verif/pkg|env/ (single-DUT files)
  src/val/tb/<blk>  -> TOP/<blk>/verif/<subpath>/
"""

REPO_ROOT = "/fake/repo"


def report_text(pairs: list[tuple[str, str]]) -> str:
    lines = [f"Repo root: {REPO_ROOT}", "Dest root: N/A", "", "--- PASS-THROUGH FILES ---"]
    for src, dst in pairs:
        lines.append(f"    SRC: {REPO_ROOT}/{src}")
        lines.append(f"    DST: {REPO_ROOT}/{dst}")
    lines.append(RULES_TEXT)
    return "\n".join(lines) + "\n"


def git(repo: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


@dataclass
class Fixture:
    repo: Path
    zenws: Path
    ws: ZenWorkspace
    base_tag: str = "base_tag"
    head_tag: str = "head_tag"


@pytest.fixture
def fixture(tmp_path: Path) -> Fixture:
    repo = tmp_path / "cheetah"
    repo.mkdir()
    git(repo, "init", "-q", "-b", "main")
    git(repo, "config", "user.email", "t@example.com")
    git(repo, "config", "user.name", "t")

    rtl = "src/rtl/bridges/a"
    write(repo / rtl / "keep.sv", "module keep;\nendmodule\n")
    write(repo / rtl / "touch.sv", "// old note\nmodule touch;\nendmodule\n")
    write(repo / rtl / "gone.sv", "module gone;\nendmodule\n")
    write(repo / rtl / "local.sv", "module local_m;\nendmodule\n")
    write(repo / rtl / "moved.sv", "module moved;\n  wire a, b, c, d, e, f;\nendmodule\n")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "base")
    git(repo, "tag", "base_tag")

    write(repo / rtl / "touch.sv", "// new note\nmodule touch;\nendmodule\n")
    write(repo / rtl / "fresh.sv", "module fresh;\nendmodule\n")
    write(repo / rtl / "local.sv", "module local_m;\n  wire w;\nendmodule\n")
    write(repo / rtl / "renamed.sv", (repo / rtl / "moved.sv").read_text())
    (repo / rtl / "moved.sv").unlink()
    (repo / rtl / "gone.sv").unlink()
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "head")
    git(repo, "tag", "head_tag")

    zenws = tmp_path / "zenws"
    components = zenws / "components"
    dest = "BLOCKS/bridges/a/design/rtl"
    # The workspace reflects base_tag, except local.sv which was edited in place.
    write(components / dest / "keep.sv", "module keep;\nendmodule\n")
    write(components / dest / "touch.sv", "// old note\nmodule touch;\nendmodule\n")
    write(components / dest / "gone.sv", "module gone;\nendmodule\n")
    write(components / dest / "local.sv", "module local_m;\n  // local edit\nendmodule\n")
    write(components / dest / "moved.sv", "module moved;\n  wire a, b, c, d, e, f;\nendmodule\n")
    write(
        components / "migration_report.txt",
        report_text(
            [
                (f"{rtl}/{name}", f"{dest}/{name}")
                for name in ("keep.sv", "touch.sv", "gone.sv", "local.sv", "moved.sv")
            ]
        ),
    )
    (components / ".git").mkdir()

    return Fixture(repo=repo, zenws=zenws, ws=load_workspace(zenws))
