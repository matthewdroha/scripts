from __future__ import annotations

from pathlib import Path

from cthrepo_to_zenws.gitdiff import (
    blob_at,
    diff_changes,
    diff_command,
    is_git_repo,
    parse_name_status,
    rev_exists,
)


def test_diff_command_is_a_plain_name_status_diff():
    args = diff_command("v1", "v2")
    assert args == ["diff", "v1", "v2", "--name-status"]
    assert "--no-renames" not in args


def test_parse_name_status_reads_a_m_d():
    changes = parse_name_status("A\tsrc/new.sv\nM\tsrc/old.sv\nD\tsrc/gone.sv\n")
    assert [(c.status, c.path) for c in changes] == [
        ("A", "src/new.sv"),
        ("M", "src/old.sv"),
        ("D", "src/gone.sv"),
    ]


def test_parse_name_status_reads_rename_with_similarity():
    change = parse_name_status("R087\tsrc/old.sv\tsrc/new.sv\n")[0]
    assert (change.status, change.old_path, change.path, change.similarity) == (
        "R",
        "src/old.sv",
        "src/new.sv",
        87,
    )


def test_parse_name_status_ignores_rename_without_a_second_path():
    assert parse_name_status("R100\tsrc/old.sv\n") == []


def test_parse_name_status_treats_typechange_as_modify():
    assert parse_name_status("T\tsrc/link.sv\n")[0].status == "M"


def test_parse_name_status_ignores_blank_and_malformed_lines():
    assert parse_name_status("\n\nnotabline\nA\tsrc/a.sv\n") == parse_name_status("A\tsrc/a.sv")


def test_diff_changes_against_real_repo(fixture):
    changes = {
        c.path.rsplit("/", 1)[-1]: c.status
        for c in diff_changes(fixture.repo, "base_tag", "head_tag")
    }
    assert changes == {
        "touch.sv": "M",
        "local.sv": "M",
        "fresh.sv": "A",
        "gone.sv": "D",
        "renamed.sv": "R",
    }


def test_blob_at_returns_none_for_missing_path(fixture):
    assert blob_at(fixture.repo, "head_tag", "src/rtl/bridges/a/gone.sv") is None
    assert blob_at(fixture.repo, "base_tag", "src/rtl/bridges/a/gone.sv") == b"module gone;\nendmodule\n"


def test_repo_and_rev_probes(fixture, tmp_path: Path):
    assert is_git_repo(fixture.repo)
    assert not is_git_repo(tmp_path / "zenws")
    assert rev_exists(fixture.repo, "base_tag")
    assert not rev_exists(fixture.repo, "no_such_tag")
