from __future__ import annotations

import os
from collections import Counter
from pathlib import Path

from find_collisions.collisions import (
    all_configrule_values,
    build_realpath_counts,
    canonicalize_source,
    collect_raw_rows,
    collect_reduced_rows,
    colliding_modules,
    modules_with_multiple_sources,
    reduced_fields,
)
from find_collisions.xmlstream import Definition

PARENT = "parent cell's library"
SEARCH = "default library search order"


def counts(*items: tuple[Definition, int]) -> Counter[Definition]:
    return Counter(dict(items))


def test_single_definition_is_not_a_collision() -> None:
    data = counts((Definition("solo", "LIB", PARENT, '"/a.sv",1'), 42))
    assert colliding_modules(data) == set()
    assert collect_raw_rows(data) == []


def test_configrule_only_difference_is_a_collision() -> None:
    data = counts(
        (Definition("m", "LIB", PARENT, '"/a.sv",1'), 3),
        (Definition("m", "LIB", SEARCH, '"/a.sv",1'), 1),
    )
    assert colliding_modules(data) == {"m"}
    assert modules_with_multiple_sources(data) == set()


def test_raw_rows_sorted_by_module_then_descending_count() -> None:
    data = counts(
        (Definition("zeta", "LIB_A", PARENT, '"/z1.sv",1'), 1),
        (Definition("zeta", "LIB_B", PARENT, '"/z2.sv",1'), 9),
        (Definition("alpha", "LIB_A", PARENT, '"/a1.sv",1'), 2),
        (Definition("alpha", "LIB_B", PARENT, '"/a2.sv",1'), 5),
    )
    rows = collect_raw_rows(data)
    assert [(r["module"], r["instance_count"]) for r in rows] == [
        ("alpha", 5),
        ("alpha", 2),
        ("zeta", 9),
        ("zeta", 1),
    ]


def test_multiple_sources_subset_of_colliding() -> None:
    data = counts(
        (Definition("m", "LIB_A", PARENT, '"/a.sv",1'), 1),
        (Definition("m", "LIB_B", PARENT, '"/a.sv",1'), 1),
        (Definition("n", "LIB_A", PARENT, '"/n1.sv",1'), 1),
        (Definition("n", "LIB_A", PARENT, '"/n2.sv",1'), 1),
    )
    assert modules_with_multiple_sources(data) <= colliding_modules(data)
    assert modules_with_multiple_sources(data) == {"n"}


def test_reduced_rows_group_by_module_and_source() -> None:
    data = counts(
        (Definition("m", "LIB_A", PARENT, '"/a.sv",1'), 3),
        (Definition("m", "LIB_B", SEARCH, '"/a.sv",1'), 4),
        (Definition("m", "LIB_C", SEARCH, '"/b.sv",2'), 5),
    )
    rows = collect_reduced_rows(data, all_configrule_values(data))
    assert [(r["source"], r["instance_count"]) for r in rows] == [
        ('"/a.sv",1', 7),
        ('"/b.sv",2', 5),
    ]
    assert rows[0]["library_count"] == 2
    assert rows[0]["config_rule_count"] == 2
    assert rows[0][PARENT] == 1 and rows[0][SEARCH] == 1
    assert rows[1][PARENT] == 0 and rows[1][SEARCH] == 1


def test_reduced_excludes_library_only_differences() -> None:
    data = counts(
        (Definition("m", "LIB_A", PARENT, '"/a.sv",1'), 1),
        (Definition("m", "LIB_B", PARENT, '"/a.sv",1'), 1),
    )
    assert collect_reduced_rows(data, all_configrule_values(data)) == []


def test_configrule_columns_cover_whole_dump() -> None:
    data = counts(
        (Definition("m", "LIB_A", PARENT, '"/a.sv",1'), 1),
        (Definition("m", "LIB_A", PARENT, '"/b.sv",1'), 1),
        (Definition("quiet", "LIB_A", "Top Module", '"/t.sv",1'), 1),
    )
    columns = all_configrule_values(data)
    assert columns == sorted(["Top Module", PARENT])
    rows = collect_reduced_rows(data, columns)
    assert all(sum(row[c] for c in columns) == row["config_rule_count"] for row in rows)
    assert all(row["Top Module"] == 0 for row in rows)


def test_reduced_fields_default_has_no_configrule_columns() -> None:
    assert reduced_fields() == reduced_fields([])
    assert "module" in reduced_fields()


def test_canonicalize_source(tmp_path: Path) -> None:
    real = tmp_path / "real.sv"
    real.write_text("")
    spelled = tmp_path / "sub" / ".." / "real.sv"
    assert canonicalize_source(f'"{spelled}",7') == f'"{os.path.realpath(real)}",7'
    assert canonicalize_source("not a source string") == "not a source string"


def test_build_realpath_counts_merges_and_filters(tmp_path: Path) -> None:
    real = tmp_path / "real.sv"
    real.write_text("")
    alias = f'"{tmp_path / "sub" / ".." / "real.sv"}",7'
    direct = f'"{real}",7'
    data = counts(
        (Definition("m", "LIB", PARENT, alias), 2),
        (Definition("m", "LIB", PARENT, direct), 3),
        (Definition("other", "LIB", PARENT, direct), 1),
    )
    merged = build_realpath_counts(data, modules={"m"})
    assert list(merged.values()) == [5]
    assert "other" not in {d.module for d in merged}


def test_realpath_collapse_removes_false_positive(tmp_path: Path) -> None:
    real = tmp_path / "real.sv"
    real.write_text("")
    data = counts(
        (Definition("m", "LIB_A", PARENT, f'"{tmp_path / "a" / ".." / "real.sv"}",7'), 1),
        (Definition("m", "LIB_B", SEARCH, f'"{tmp_path / "b" / ".." / "real.sv"}",7'), 1),
    )
    assert modules_with_multiple_sources(data) == {"m"}
    merged = build_realpath_counts(data, modules=colliding_modules(data))
    assert collect_reduced_rows(merged, all_configrule_values(data)) == []


def test_differing_line_numbers_stay_distinct(tmp_path: Path) -> None:
    real = tmp_path / "real.sv"
    real.write_text("")
    data = counts(
        (Definition("m", "LIB", PARENT, f'"{real}",1'), 1),
        (Definition("m", "LIB", PARENT, f'"{real}",2'), 1),
    )
    merged = build_realpath_counts(data)
    assert len(merged) == 2
