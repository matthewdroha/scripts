from __future__ import annotations

from pathlib import Path

from cthrepo_to_zenws.gitdiff import diff_changes
from cthrepo_to_zenws.plan import (
    BUCKET_AUTO_DELETE,
    BUCKET_AUTO_RENAME,
    BUCKET_AUTO_UPDATE,
    BUCKET_MANUAL_MERGE,
    BUCKET_MANUAL_RENAME,
    BUCKET_REVIEW_COMMENT_ONLY,
    BUCKET_SKIP_IGNORED,
    BUCKET_SKIP_NOT_MIGRATED,
    BUCKET_ORDER,
    build_plan,
    matches_any,
    parse_pattern_file,
)

RTL = "src/rtl/bridges/a"


def plan(fixture, ignore=None):
    changes = diff_changes(fixture.repo, fixture.base_tag, fixture.head_tag)
    rows = build_plan(changes, fixture.ws, fixture.repo, fixture.base_tag, fixture.head_tag, ignore)
    return {row.filename: row for row in rows}


def test_comment_only_modify_needs_review(fixture):
    assert plan(fixture)["touch.sv"].bucket == BUCKET_REVIEW_COMMENT_ONLY


def test_locally_modified_file_needs_a_manual_merge(fixture):
    row = plan(fixture)["local.sv"]
    assert row.bucket == BUCKET_MANUAL_MERGE
    assert fixture.base_tag in row.notes


def test_clean_delete_is_automatic(fixture):
    assert plan(fixture)["gone.sv"].bucket == BUCKET_AUTO_DELETE


def test_added_file_gets_a_destination(fixture):
    row = plan(fixture)["fresh.sv"]
    assert row.zen_path.endswith("/fresh.sv")
    assert row.change == "add"


def test_every_row_records_the_rule_that_resolved_it(fixture):
    for row in plan(fixture).values():
        assert row.resolution

def test_clean_rename_is_automatic(fixture):
    row = plan(fixture)["renamed.sv"]
    assert row.bucket == BUCKET_AUTO_RENAME
    assert row.change == "rename"
    assert row.old_zen_path.endswith("/moved.sv")
    assert row.zen_path.endswith("/renamed.sv")


def test_rename_of_a_locally_modified_file_is_manual(fixture):
    fixture.ws.abs_path("BLOCKS/bridges/a/design/rtl/moved.sv").write_text("module moved;\n")
    assert plan(fixture)["renamed.sv"].bucket == BUCKET_MANUAL_RENAME


def test_rename_whose_source_was_never_migrated_is_planned_as_an_add(fixture):
    fixture.ws.abs_path("BLOCKS/bridges/a/design/rtl/moved.sv").unlink()
    row = plan(fixture)["renamed.sv"]
    assert row.old_zen_path is None
    assert "never migrated" in row.notes


def test_ignore_patterns_short_circuit_planning(fixture):
    rows = plan(fixture, ignore=[f"{RTL}/*"])
    assert {row.bucket for row in rows.values()} == {BUCKET_SKIP_IGNORED}
    assert all(row.csv_zen_path() == "" for row in rows.values())


def test_up_to_date_workspace_copy_is_skipped(fixture):
    target = fixture.ws.abs_path(f"BLOCKS/bridges/a/design/rtl/touch.sv")
    target.write_text("// new note\nmodule touch;\nendmodule\n")
    assert plan(fixture)["touch.sv"].bucket == "skip-up-to-date"


def test_delete_of_unmigrated_file_is_skipped(fixture):
    fixture.ws.abs_path("BLOCKS/bridges/a/design/rtl/gone.sv").unlink()
    assert plan(fixture)["gone.sv"].bucket == BUCKET_SKIP_NOT_MIGRATED


def test_clean_content_change_is_automatic(fixture):
    src = fixture.repo / RTL / "keep.sv"
    assert src.exists()
    changes = diff_changes(fixture.repo, fixture.base_tag, fixture.head_tag)
    fixture.ws.abs_path("BLOCKS/bridges/a/design/rtl/local.sv").write_text(
        "module local_m;\nendmodule\n"
    )
    rows = {r.filename: r for r in build_plan(changes, fixture.ws, fixture.repo, fixture.base_tag, fixture.head_tag)}
    assert rows["local.sv"].bucket == BUCKET_AUTO_UPDATE


def test_rows_are_sorted_by_bucket_order(fixture):
    changes = diff_changes(fixture.repo, fixture.base_tag, fixture.head_tag)
    rows = build_plan(changes, fixture.ws, fixture.repo, fixture.base_tag, fixture.head_tag)
    indexes = [BUCKET_ORDER.index(row.bucket) for row in rows]
    assert indexes == sorted(indexes)


def test_pattern_file_skips_blanks_and_comments(tmp_path: Path):
    path = tmp_path / "ignore.txt"
    path.write_text("# comment\n\nverif/*\n  syn/*  \n")
    patterns = parse_pattern_file(path)
    assert patterns == ["verif/*", "syn/*"]
    assert matches_any("verif/sim/a.sh", patterns)
    assert not matches_any("src/rtl/a.sv", patterns)
