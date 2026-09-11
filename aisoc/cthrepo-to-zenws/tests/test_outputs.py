from __future__ import annotations

import shlex
import subprocess
import time
from pathlib import Path

import pytest

from cthrepo_to_zenws.gitdiff import diff_changes, diff_command
from cthrepo_to_zenws.outputs import (
    BUCKET_MEANING,
    OUTPUT_PREFIX,
    REVIEW_SRC_DIRNAME,
    RunInfo,
    bucket_counts,
    csv_filename,
    render_csv,
    render_replay,
    render_replay_review,
    render_summary,
    write_outputs,
)
from cthrepo_to_zenws.plan import NO_ACTION_BUCKETS, build_plan


@pytest.fixture
def planned(fixture):
    changes = diff_changes(fixture.repo, fixture.base_tag, fixture.head_tag)
    rows = build_plan(changes, fixture.ws, fixture.repo, fixture.base_tag, fixture.head_tag)
    start = time.time()
    info = RunInfo(
        command_line=f"{OUTPUT_PREFIX} --dry-run",
        cheetah_repo=fixture.repo,
        zenws_repo=fixture.zenws,
        dest_root=fixture.ws.dest_root,
        base_tag=fixture.base_tag,
        head_tag=fixture.head_tag,
        diff_command=diff_command(fixture.base_tag, fixture.head_tag),
        report_path=fixture.ws.dest_root / "migration_report.txt",
        mapping_entries=len(fixture.ws.mapping),
        category_rules=len(fixture.ws.category_rules),
        start_epoch=start,
        end_epoch=start + 1.5,
    )
    return rows, info


def test_csv_has_header_and_one_row_per_file(planned):
    rows, _ = planned
    lines = render_csv(rows).strip().splitlines()
    assert lines[0] == (
        "filename,cheetah_source_path,change,resolution_rule,action_bucket,"
        "zen_destination_path,zen_previous_path,notes"
    )
    assert len(lines) == len(rows) + 1


def test_csv_reports_the_resolution_rule_before_the_bucket(planned):
    rows, _ = planned
    header, *body = render_csv(rows).strip().splitlines()
    columns = header.split(",")
    assert columns.index("resolution_rule") == columns.index("action_bucket") - 1
    rule_column = {line.split(",")[columns.index("resolution_rule")] for line in body}
    assert rule_column <= {
        "migration-report",
        "identity-path",
        "sibling-directory",
        "category-rule",
        "identity-directory",
        "unique-basename",
        "unresolved",
        "not-resolved",
    }


def test_csv_filename_is_timestamped():
    assert csv_filename(0).startswith(f"{OUTPUT_PREFIX}.csv.")


def test_replay_is_executable_bash(planned, tmp_path: Path):
    rows, info = planned
    script = tmp_path / "replay.sh"
    script.write_text(render_replay(rows, info))
    result = subprocess.run(["bash", str(script)], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr


def test_replay_applies_automatic_actions_only(planned, fixture):
    rows, info = planned
    script = fixture.zenws / "replay.sh"
    script.write_text(render_replay(rows, info))
    subprocess.run(["bash", str(script)], check=True, capture_output=True)
    dest = fixture.ws.dest_root / "BLOCKS/bridges/a/design/rtl"
    assert not (dest / "gone.sv").exists()  # auto-delete ran
    assert not (dest / "moved.sv").exists()  # auto-rename removed the old path
    assert (dest / "renamed.sv").exists()  # auto-rename wrote the new path
    assert "old note" in (dest / "touch.sv").read_text()  # comment-only left alone


def test_replay_comments_out_every_non_automatic_action(planned):
    rows, info = planned
    text = render_replay(rows, info)
    for row in rows:
        if row.bucket.startswith(("review", "manual")):
            assert f"# TODO({row.bucket})" in text


def _meld_args(line: str) -> list[str]:
    """The path arguments of a meld line, live or commented, minus the trailing reason."""
    body = line.lstrip("# ").split(" # ")[0]
    if not body.startswith("meld "):
        return []
    return [arg for arg in shlex.split(body)[1:] if arg != "?"]


def test_review_keeps_the_replay_bucket_order(planned, tmp_path: Path):
    rows, info = planned
    text = render_replay_review(rows, info, tmp_path / "src")
    headers = [line for line in text.splitlines() if line.startswith("# ---- ")]
    assert headers == [
        line for line in render_replay(rows, info).splitlines() if line.startswith("# ---- ")
    ]


def test_review_lists_every_actionable_row_once(planned, tmp_path: Path):
    rows, info = planned
    text = render_replay_review(rows, info, tmp_path / "src")
    actionable = [row for row in rows if row.bucket not in NO_ACTION_BUCKETS]
    assert sum(1 for line in text.splitlines() if _meld_args(line)) == len(actionable)


def test_review_comments_out_rows_with_nothing_to_diff(planned, tmp_path: Path):
    rows, info = planned
    text = render_replay_review(rows, info, tmp_path / "src")
    for line in text.splitlines():
        args = _meld_args(line)
        if len(args) == 2 and not line.startswith("#"):
            assert Path(args[1]).is_file(), f"live meld line points at a missing file: {line}"
    assert any(
        line.startswith("# meld") and "destination does not exist yet" in line
        for line in text.splitlines()
    )


def test_review_diffs_a_rename_against_the_old_zen_copy(planned, tmp_path: Path):
    rows, info = planned
    text = render_replay_review(rows, info, tmp_path / "src")
    renames = [row for row in rows if row.change == "rename" and row.old_zen_path]
    assert renames
    for row in renames:
        assert str(info.dest_root / row.old_zen_path) in text


def test_summary_reports_command_line_and_both_time_formats(planned):
    rows, info = planned
    text = render_summary(rows, info)
    assert f"command line      : {info.command_line}" in text
    assert "start time        :" in text
    assert "end time          :" in text
    assert f"start epoch       : {info.start_epoch:.6f}" in text
    assert f"end epoch         : {info.end_epoch:.6f}" in text


def test_summary_totals_add_up(planned):
    rows, info = planned
    text = render_summary(rows, info)
    assert f"files in diff     : {len(rows)}" in text
    assert sum(n for _, n in bucket_counts(rows)) == len(rows)


def test_summary_explains_every_bucket_it_reports(planned):
    rows, info = planned
    text = render_summary(rows, info)
    legend = text.split("-- what each action bucket means --", 1)[1]
    for bucket, _ in bucket_counts(rows):
        assert f"{bucket} " in legend or f"{bucket} :" in legend
        assert BUCKET_MEANING[bucket] in legend


def test_write_outputs_creates_the_three_artifacts(planned, tmp_path: Path):
    rows, info = planned
    outdir = tmp_path / "out"
    outdir.mkdir()
    written = write_outputs(outdir, rows, info, debug=0, force=False)
    names = sorted(p.name for p in written)
    assert f"{OUTPUT_PREFIX}.replay" in names
    assert f"{OUTPUT_PREFIX}.replay.review" in names
    assert f"{OUTPUT_PREFIX}.summary" in names
    assert any(n.startswith(f"{OUTPUT_PREFIX}.csv.") for n in names)
    assert (outdir / f"{OUTPUT_PREFIX}.replay").stat().st_mode & 0o111


def test_write_outputs_stages_every_meld_source_it_names(planned, tmp_path: Path):
    rows, info = planned
    outdir = tmp_path / "out"
    outdir.mkdir()
    write_outputs(outdir, rows, info, debug=0, force=False)
    src_root = outdir / REVIEW_SRC_DIRNAME
    staged = [
        arg
        for line in (outdir / f"{OUTPUT_PREFIX}.replay.review").read_text().splitlines()
        for arg in _meld_args(line)
        if arg.startswith(str(src_root))
    ]
    assert staged, "expected at least one staged cheetah source"
    for path in staged:
        assert Path(path).is_file(), f"{path} was named but never extracted"


def test_write_outputs_refuses_to_clobber_without_force(planned, tmp_path: Path):
    rows, info = planned
    outdir = tmp_path / "out"
    outdir.mkdir()
    write_outputs(outdir, rows, info, debug=0, force=False)
    with pytest.raises(FileExistsError):
        write_outputs(outdir, rows, info, debug=0, force=False)
    write_outputs(outdir, rows, info, debug=0, force=True)


def test_log_is_written_only_when_debug_requested(planned, tmp_path: Path):
    rows, info = planned
    quiet, loud = tmp_path / "a", tmp_path / "b"
    quiet.mkdir()
    loud.mkdir()
    write_outputs(quiet, rows, info, debug=0, force=False)
    write_outputs(loud, rows, info, debug=5, force=False)
    assert not (quiet / f"{OUTPUT_PREFIX}.log").exists()
    assert (loud / f"{OUTPUT_PREFIX}.log").exists()
