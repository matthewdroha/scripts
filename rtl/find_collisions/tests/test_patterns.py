from __future__ import annotations

from pathlib import Path

import pytest

from find_collisions.paths import PreflightError
from find_collisions.patterns import (
    EXACT,
    REGEX,
    Matcher,
    load_patterns,
    parse_patterns,
    pattern_rows,
)


def test_parse_patterns_skips_comments_and_blanks() -> None:
    patterns = parse_patterns(["# comment", "", "   ", "xor_gate", '  r"fblp_fcr"  '])
    assert [(p.raw, p.kind) for p in patterns] == [
        ("xor_gate", EXACT),
        ('r"fblp_fcr"', REGEX),
    ]


def test_parse_patterns_multiple_per_line() -> None:
    patterns = parse_patterns(['alpha beta r"ga+mma" delta'])
    assert [p.raw for p in patterns] == ["alpha", "beta", 'r"ga+mma"', "delta"]


def test_parse_patterns_regex_may_contain_spaces() -> None:
    (pattern,) = parse_patterns(['r"foo bar"'])
    assert pattern.kind == REGEX
    assert pattern.matches("x_foo bar_y")


def test_parse_patterns_rejects_bad_regex() -> None:
    with pytest.raises(PreflightError, match="bad regex"):
        parse_patterns(['r"("'])


def test_exact_pattern_requires_full_name() -> None:
    (pattern,) = parse_patterns(["xor_gate"])
    assert pattern.matches("xor_gate")
    assert not pattern.matches("xor_gate_2")
    assert not pattern.matches("my_xor_gate")


def test_regex_pattern_matches_anywhere() -> None:
    (pattern,) = parse_patterns(['r"xor"'])
    assert pattern.matches("xor")
    assert pattern.matches("my_xor_gate")
    assert not pattern.matches("and_gate")


def test_matcher_unions_patterns_and_caches() -> None:
    matcher = Matcher(parse_patterns(['xor_gate r"fblp_fcr"']))
    assert matcher("xor_gate")
    assert matcher("fblp_fcr_ctrl")
    assert not matcher("and_gate")
    assert matcher("xor_gate")  # cached path
    assert matcher._cache == {"xor_gate": True, "fblp_fcr_ctrl": True, "and_gate": False}


def test_pattern_rows_count_distinct_modules() -> None:
    patterns = parse_patterns(['xor_gate r"fblp_fcr" r"nomatch"'])
    rows = pattern_rows(patterns, ["xor_gate", "fblp_fcr_ctrl", "fblp_fcr_top", "and_gate"])
    assert [(r["pattern"], r["matched_modules"]) for r in rows] == [
        ("xor_gate", 1),
        ('r"fblp_fcr"', 2),
        ('r"nomatch"', 0),
    ]


def test_load_patterns_missing_file(tmp_path: Path) -> None:
    with pytest.raises(PreflightError, match="missing module file"):
        load_patterns(tmp_path / "nope.md")


def test_load_patterns_empty_file(tmp_path: Path) -> None:
    path = tmp_path / "modules.md"
    path.write_text("# only a comment\n\n")
    with pytest.raises(PreflightError, match="no patterns"):
        load_patterns(path)


def test_load_patterns_reads_file(tmp_path: Path) -> None:
    path = tmp_path / "modules.md"
    path.write_text('# Test module list for IMH\nxor_gate\nr"fblp_fcr"\n')
    assert [p.raw for p in load_patterns(path)] == ["xor_gate", 'r"fblp_fcr"']
