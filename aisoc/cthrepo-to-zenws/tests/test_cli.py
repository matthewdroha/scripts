from __future__ import annotations

from pathlib import Path

import pytest

from cthrepo_to_zenws import main
from cthrepo_to_zenws.cli import build_parser
from cthrepo_to_zenws.outputs import OUTPUT_PREFIX


def base_argv(fixture) -> list[str]:
    return [
        "--cheetah-repo",
        str(fixture.repo),
        "--zenws-repo",
        str(fixture.zenws),
        "--cheetah-tag-used-for-existing-zenws",
        fixture.base_tag,
        "--cheetah-tag-to-graft-to-zenws",
        fixture.head_tag,
    ]


def test_parser_exposes_the_required_flags():
    options = {action.dest for action in build_parser()._actions}
    assert {"dry_run", "force", "verbose", "debug"} <= options


def test_dry_run_reports_counts_and_writes_nothing(fixture, capsys):
    assert main([*base_argv(fixture), "--dry-run"]) == 0
    assert "changed files" in capsys.readouterr().out
    assert not (fixture.zenws / f"{OUTPUT_PREFIX}.replay").exists()


def test_real_run_writes_outputs_into_the_workspace(fixture, capsys):
    assert main(base_argv(fixture)) == 0
    assert (fixture.zenws / f"{OUTPUT_PREFIX}.replay").exists()
    assert (fixture.zenws / f"{OUTPUT_PREFIX}.summary").exists()
    assert "wrote" in capsys.readouterr().out


def test_outdir_redirects_the_artifacts(fixture, tmp_path: Path):
    outdir = tmp_path / "reports"
    assert main([*base_argv(fixture), "--outdir", str(outdir)]) == 0
    assert (outdir / f"{OUTPUT_PREFIX}.summary").exists()


def test_second_run_needs_force(fixture, capsys):
    assert main(base_argv(fixture)) == 0
    assert main(base_argv(fixture)) == 2
    assert "--force" in capsys.readouterr().err
    assert main([*base_argv(fixture), "--force"]) == 0


def test_verbose_logs_to_stderr(fixture, capsys):
    main([*base_argv(fixture), "--dry-run", "--verbose"])
    assert f"{OUTPUT_PREFIX}: " in capsys.readouterr().err


def test_debug_level_writes_a_log(fixture):
    main([*base_argv(fixture), "--debug", "3"])
    assert (fixture.zenws / f"{OUTPUT_PREFIX}.log").exists()


def test_missing_repo_fails_preflight(fixture, tmp_path: Path, capsys):
    argv = base_argv(fixture)
    argv[1] = str(tmp_path / "nope")
    assert main(argv) == 2
    assert "cheetah repo not found" in capsys.readouterr().err


def test_unknown_tag_fails_preflight(fixture, capsys):
    argv = base_argv(fixture)
    argv[-1] = "no_such_tag"
    assert main(argv) == 2
    assert "tag not found" in capsys.readouterr().err


def test_workspace_without_a_report_fails_preflight(fixture, tmp_path: Path, capsys):
    empty = tmp_path / "empty"
    empty.mkdir()
    argv = base_argv(fixture)
    argv[3] = str(empty)
    assert main(argv) == 2
    assert "migration_report.txt" in capsys.readouterr().err


def test_ignore_file_must_exist(fixture, tmp_path: Path, capsys):
    assert main([*base_argv(fixture), "--ignore", str(tmp_path / "nope.txt")]) == 2
    assert "ignore file not found" in capsys.readouterr().err


def test_help_exits_zero():
    with pytest.raises(SystemExit) as excinfo:
        main(["--help"])
    assert excinfo.value.code == 0
