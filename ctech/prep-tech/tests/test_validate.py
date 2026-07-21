import pytest

from prep_tech import validate
from prep_tech.config import parse_input


def _write(path, text):
    with open(path, "w") as f:
        f.write(text)
    return path


# ---------------------------------------------------------------------------
# config.parse_input
# ---------------------------------------------------------------------------

def test_parse_input(tmp_path):
    md = _write(
        tmp_path / "prep_tech.input.md",
        "## Cheetah backend reference\n"
        "/path/to/cheetah/backend\n"
        "\n"
        "# a comment line, ignored\n"
        "## CORIMH DIE\n"
        "76p4_g1i_opt4.cth\n"
        "76p4_g1m_opt4.cth\n"
        "/path/to/ctech/dir1\n"
        "/path/to/ctech/dir2\n",
    )
    parsed = parse_input(str(md))
    assert parsed["cheetah_backend"] == "/path/to/cheetah/backend"
    assert list(parsed["dies"]) == ["corimh"]
    die = parsed["dies"]["corimh"]
    assert die["cth_files"] == ["76p4_g1i_opt4.cth", "76p4_g1m_opt4.cth"]
    assert die["ctech_dirs"] == ["/path/to/ctech/dir1", "/path/to/ctech/dir2"]


def test_parse_input_multiple_dies(tmp_path):
    md = _write(
        tmp_path / "in.md",
        "## Cheetah backend reference\n/bk\n"
        "## CORIMH DIE\na.cth\n/d1\n"
        "## CORCBBP DIE\nb.cth\n/d2\n",
    )
    parsed = parse_input(str(md))
    assert set(parsed["dies"]) == {"corimh", "corcbbp"}


def test_parse_input_regex(tmp_path):
    md = _write(
        tmp_path / "in.md",
        "## Cheetah backend reference\n/bk\n"
        "## CORIMH DIE\n"
        "/ctech/dir1\n"
        "76p5_g1i_opt8.cth  REGEX=tttt\\S+850v\\S+100c\n"
        "76p5_g1m_opt8.cth  REGEX=tttt\\S+850v\\S+100c\n"
        "78p6_i0m_opt26.cth REGEX=tttt\\S+850v\\S+100c\\S+cmax\n",
    )
    parsed = parse_input(str(md))
    die = parsed["dies"]["corimh"]
    # Bare .cth filenames (regex stripped off).
    assert die["cth_files"] == [
        "76p5_g1i_opt8.cth",
        "76p5_g1m_opt8.cth",
        "78p6_i0m_opt26.cth",
    ]
    assert die["ctech_dirs"] == ["/ctech/dir1"]
    # Union of regexes, de-duplicated, order-preserving.
    assert die["regexes"] == [
        "tttt\\S+850v\\S+100c",
        "tttt\\S+850v\\S+100c\\S+cmax",
    ]


def test_parse_input_no_regex_key_empty(tmp_path):
    md = _write(
        tmp_path / "in.md",
        "## Cheetah backend reference\n/bk\n## CORIMH DIE\na.cth\n/d1\n",
    )
    parsed = parse_input(str(md))
    assert parsed["dies"]["corimh"]["regexes"] == []



# ---------------------------------------------------------------------------
# validate.*
# ---------------------------------------------------------------------------

def test_validate_ctech_directories_ok(tmp_path):
    d1 = tmp_path / "ctech1"
    d1.mkdir()
    # Should not raise.
    validate.validate_ctech_directories({"corimh": [str(d1)]})


def test_validate_ctech_directories_missing(tmp_path):
    with pytest.raises(FileNotFoundError):
        validate.validate_ctech_directories(
            {"corimh": [str(tmp_path / "does_not_exist")]}
        )


def test_validate_cth_files_ok(tmp_path):
    _write(tmp_path / "a.cth", "")
    validate.validate_cth_files(["a.cth"], str(tmp_path))


def test_validate_cth_files_missing(tmp_path):
    with pytest.raises(FileNotFoundError):
        validate.validate_cth_files(["missing.cth"], str(tmp_path))


def test_pre_flight_validation_ok(tmp_path):
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(tmp_path / "a.cth", "")
    validate.pre_flight_validation(
        {"corimh": [str(ctech)]}, ["a.cth"], str(tmp_path)
    )


def test_pre_flight_validation_raises(tmp_path):
    with pytest.raises(FileNotFoundError):
        validate.pre_flight_validation(
            {"corimh": [str(tmp_path / "nope")]}, [], str(tmp_path)
        )