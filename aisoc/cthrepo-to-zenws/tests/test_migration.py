from __future__ import annotations

from cthrepo_to_zenws.migration import (
    directory_map,
    parent_dir,
    parse_category_rules,
    parse_migration_report,
)

from conftest import RULES_TEXT, report_text


def test_parse_migration_report_makes_paths_relative_to_repo_root():
    text = report_text([("src/rtl/a/x.sv", "BLOCKS/a/design/rtl/x.sv")])
    assert parse_migration_report(text) == {"src/rtl/a/x.sv": "BLOCKS/a/design/rtl/x.sv"}


def test_parse_migration_report_drops_pairs_outside_repo_root():
    text = "Repo root: /fake/repo\n    SRC: /elsewhere/x.sv\n    DST: /fake/repo/COMMON/x.sv\n"
    assert parse_migration_report(text) == {}


def test_parse_migration_report_ignores_src_without_dst():
    text = "Repo root: /fake/repo\n    SRC: /fake/repo/a.sv\n    SRC: /fake/repo/b.sv\n    DST: /fake/repo/B.sv\n"
    assert parse_migration_report(text) == {"b.sv": "B.sv"}


def test_parent_dir():
    assert parent_dir("a/b/c.sv") == "a/b"
    assert parent_dir("c.sv") == ""


def test_directory_map_keeps_only_unambiguous_directories():
    mapping = {
        "src/a/x.sv": "DST/a/x.sv",
        "src/a/y.sv": "DST/a/y.sv",
        "src/b/x.sv": "DST/b/x.sv",
        "src/b/y.sv": "OTHER/b/y.sv",
    }
    assert directory_map(mapping) == {"src/a": "DST/a"}


def test_category_rule_substitutes_block_placeholder():
    rules = {r.source: r for r in parse_category_rules(RULES_TEXT)}
    rule = rules["src/rtl/bridges/<block>/"]
    assert rule.apply("src/rtl/bridges/ic2axi/uic.sv") == "BLOCKS/bridges/ic2axi/design/rtl/uic.sv"


def test_category_rule_appends_remaining_subpath():
    rules = {r.source: r for r in parse_category_rules(RULES_TEXT)}
    assert (
        rules["src/rtl/pkg/"].apply("src/rtl/pkg/sub/p.svh") == "COMMON/pkg/design/rtl/sub/p.svh"
    )


def test_category_rule_does_not_match_unrelated_path():
    rules = parse_category_rules(RULES_TEXT)
    assert all(rule.apply("verif/sim/run.sh") is None for rule in rules)


def test_ambiguous_and_alternation_rules_are_dropped():
    sources = [rule.source for rule in parse_category_rules(RULES_TEXT)]
    assert "src/val/vip/" not in sources
    assert "src/val/fv/" in sources


def test_rules_sorted_most_literal_first():
    sources = [rule.source for rule in parse_category_rules(RULES_TEXT)]
    assert sources.index("src/rtl/pkg/") < sources.index("src/val/tb/<blk>")
