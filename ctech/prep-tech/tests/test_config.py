"""prep_tech.config: prep_tech.input.md parsing (spec 2.1)."""

import pytest

from prep_tech.config import InputFormatError, parse_input


def test_parse_input_classifies_by_filesystem_type(tmp_path, write):
    d1 = tmp_path / "ctech1"
    d1.mkdir()
    d2 = tmp_path / "ctech2"
    d2.mkdir()
    cfg1 = write(tmp_path / "g1i.cth", "")
    cfg2 = write(tmp_path / "g1m.cth", "")
    md = write(
        tmp_path / "prep_tech.input.md",
        "# a comment line, ignored\n"
        "## CORIMH DIE\n"
        f"{cfg1}\n{cfg2}\n{d1}\n{d2}\n",
    )

    parsed = parse_input(md)

    assert list(parsed["dies"]) == ["corimh"]
    die = parsed["dies"]["corimh"]
    assert die["config_files"] == [cfg1, cfg2]
    assert die["ctech_dirs"] == [str(d1), str(d2)]
    assert die["missing"] == []


def test_parse_input_multiple_dies(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    d = tmp_path / "d1"
    d.mkdir()
    md = write(
        tmp_path / "in.md",
        f"## CORIMH DIE\n{cfg}\n{d}\n## CORCBBP DIE\n{cfg}\n{d}\n",
    )
    assert set(parse_input(md)["dies"]) == {"corimh", "corcbbp"}


def test_parse_input_ip_section_suffix(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(tmp_path / "in.md", f"## SBE IP\n{cfg}\n")
    assert list(parse_input(md)["dies"]) == ["sbe_ip"]


def test_parse_input_records_section_kind(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(tmp_path / "in.md", f"## CORIMH DIE\n{cfg}\n## SBE IP\n{cfg}\n")
    dies = parse_input(md)["dies"]
    assert dies["corimh"]["kind"] == "die"
    assert dies["sbe_ip"]["kind"] == "ip"


def test_parse_input_regex_raw_string(tmp_path, write):
    cfg = write(tmp_path / "76p5_g1i_opt8.cth", "")
    md = write(
        tmp_path / "in.md",
        f'## CORIMH DIE\n{cfg}  REGEX=r"tttt_0p850v(_0p850v)?_100c"\n',
    )
    die = parse_input(md)["dies"]["corimh"]
    assert die["config_files"] == [cfg]
    assert die["regexes"] == ["tttt_0p850v(_0p850v)?_100c"]


def test_parse_input_regex_single_quotes(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(tmp_path / "in.md", f"## D DIE\n{cfg} REGEX=r'850v'\n")
    assert parse_input(md)["dies"]["d"]["regexes"] == ["850v"]


def test_parse_input_regex_backslashes_are_literal(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(
        tmp_path / "in.md",
        f'## D DIE\n{cfg} REGEX=r"tttt_0p850v(_0p850v)?_100c\\S+cmax"\n',
    )
    assert parse_input(md)["dies"]["d"]["regexes"] == [
        r"tttt_0p850v(_0p850v)?_100c\S+cmax"
    ]


def test_parse_input_rejects_slash_delimited_regex(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(tmp_path / "in.md", f"## D DIE\n{cfg} REGEX=/850v/\n")
    with pytest.raises(InputFormatError):
        parse_input(md)


def test_parse_input_rejects_unquoted_regex(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(tmp_path / "in.md", f"## D DIE\n{cfg} REGEX=850v\n")
    with pytest.raises(InputFormatError):
        parse_input(md)


def test_parse_input_regexes_union_across_lines(tmp_path, write):
    cfg1 = write(tmp_path / "a.cth", "")
    cfg2 = write(tmp_path / "b.cth", "")
    md = write(
        tmp_path / "in.md",
        f'## D DIE\n{cfg1} REGEX=r"650v"\n{cfg2} REGEX=r"850v"\n',
    )
    assert parse_input(md)["dies"]["d"]["regexes"] == ["650v", "850v"]


def test_parse_input_no_suffix_config(tmp_path, write):
    cfg = write(tmp_path / "CORIOHA0_1p0_g1i", "")
    d = tmp_path / "ctech"
    d.mkdir()
    md = write(tmp_path / "in.md", f"## D DIE\n{d}\n{cfg}\n")
    die = parse_input(md)["dies"]["d"]
    assert die["config_files"] == [cfg]
    assert die["ctech_dirs"] == [str(d)]


def test_parse_input_records_missing_paths(tmp_path, write):
    md = write(tmp_path / "in.md", f"## D DIE\n{tmp_path / 'nope'}\n")
    assert parse_input(md)["dies"]["d"]["missing"] == [str(tmp_path / "nope")]


def test_parse_input_ignores_comments_and_blanks(tmp_path, write):
    cfg = write(tmp_path / "a.cth", "")
    md = write(tmp_path / "in.md", f"## D DIE\n\n# skip me\n{cfg}\n\n")
    die = parse_input(md)["dies"]["d"]
    assert die["config_files"] == [cfg]
    assert die["missing"] == []
