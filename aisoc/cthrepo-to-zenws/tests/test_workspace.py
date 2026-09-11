from __future__ import annotations

from pathlib import Path

from cthrepo_to_zenws.workspace import (
    build_basename_index,
    destination_candidates,
    discover_subrepos,
    find_migration_report,
    resolve_destination,
)

RTL = "src/rtl/bridges/a"
DEST = "BLOCKS/bridges/a/design/rtl"


def test_discovers_subrepos_and_report(fixture):
    assert discover_subrepos(fixture.zenws) == ["components"]
    assert find_migration_report(fixture.zenws).name == "migration_report.txt"


def test_dest_root_is_the_report_directory(fixture):
    assert fixture.ws.dest_root == fixture.zenws / "components"


def test_basename_index_skips_git_directories(fixture, tmp_path: Path):
    index = build_basename_index(fixture.ws.dest_root)
    assert index["keep.sv"] == [f"{DEST}/keep.sv"]
    assert all(not p.startswith(".git/") for paths in index.values() for p in paths)


def test_migration_report_is_the_first_candidate(fixture):
    candidates = destination_candidates(fixture.ws, f"{RTL}/keep.sv")
    assert candidates[0].source == "migration-report"
    assert candidates[0].path == f"{DEST}/keep.sv"


def test_sibling_directory_places_a_new_file(fixture):
    resolution = resolve_destination(fixture.ws, f"{RTL}/fresh.sv")
    assert resolution.path == f"{DEST}/fresh.sv"
    assert resolution.source in ("sibling-directory", "category-rule")


def test_existing_file_outranks_a_speculative_rule(fixture):
    """A candidate that names a real file wins over a higher-ranked guess."""
    resolution = resolve_destination(fixture.ws, f"{RTL}/keep.sv")
    assert fixture.ws.exists(resolution.path)


def test_unresolvable_path_reports_unresolved(fixture):
    assert resolve_destination(fixture.ws, "verif/sim/nowhere.xyz").path is None


def test_only_one_category_rule_is_offered(fixture):
    sources = [c.source for c in destination_candidates(fixture.ws, f"{RTL}/brand_new.sv")]
    assert sources.count("category-rule") <= 1
