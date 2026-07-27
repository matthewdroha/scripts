import pytest

from prep_tech import validate
from prep_tech.config import parse_input


def _write(path, text):
    with open(path, "w") as f:
        f.write(text)
    return path


def _die(config_files, ctech_dirs, regexes=None):
    return {
        "config_files": list(config_files),
        "ctech_dirs": list(ctech_dirs),
        "regexes": list(regexes or []),
    }


# ---------------------------------------------------------------------------
# config.parse_input (paths classified by filesystem type)
# ---------------------------------------------------------------------------

def test_parse_input(tmp_path):
    # Real ctech directories + real absolute config files.
    d1 = tmp_path / "ctech1"; d1.mkdir()
    d2 = tmp_path / "ctech2"; d2.mkdir()
    cfg1 = _write(tmp_path / "g1i.cth", "")
    cfg2 = _write(tmp_path / "g1m.cth", "")
    md = _write(
        tmp_path / "prep_tech.input.md",
        "# a comment line, ignored\n"
        "## CORIMH DIE\n"
        f"{cfg1}\n{cfg2}\n{d1}\n{d2}\n",
    )
    parsed = parse_input(str(md))
    assert "cheetah_backend" not in parsed
    assert list(parsed["dies"]) == ["corimh"]
    die = parsed["dies"]["corimh"]
    # Files -> config_files; directories -> ctech_dirs.
    assert die["config_files"] == [str(cfg1), str(cfg2)]
    assert die["ctech_dirs"] == [str(d1), str(d2)]


def test_parse_input_multiple_dies(tmp_path):
    cfg = _write(tmp_path / "a.cth", "")
    d = tmp_path / "d1"; d.mkdir()
    md = _write(
        tmp_path / "in.md",
        f"## CORIMH DIE\n{cfg}\n{d}\n## CORCBBP DIE\n{cfg}\n{d}\n",
    )
    parsed = parse_input(str(md))
    assert set(parsed["dies"]) == {"corimh", "corcbbp"}


def test_parse_input_regex_slashes(tmp_path):
    # REGEX=/<pat>/ inner pattern is captured; config is a file path.
    cfg = _write(tmp_path / "76p5_g1i_opt8.cth", "")
    md = _write(
        tmp_path / "in.md",
        "## CORIMH DIE\n"
        f"{cfg}  REGEX=/tttt_0p850v(_0p850v)?_100c/\n",
    )
    parsed = parse_input(str(md))
    die = parsed["dies"]["corimh"]
    assert die["config_files"] == [str(cfg)]
    assert die["regexes"] == ["tttt_0p850v(_0p850v)?_100c"]


def test_parse_input_no_suffix_config(tmp_path):
    # A config file need not end in .cth; classified as a file.
    cfg = _write(tmp_path / "CORIOHA0_1p0_g1i", "")
    d = tmp_path / "ctech"; d.mkdir()
    md = _write(tmp_path / "in.md", f"## D DIE\n{d}\n{cfg}\n")
    parsed = parse_input(str(md))
    assert parsed["dies"]["d"]["config_files"] == [str(cfg)]
    assert parsed["dies"]["d"]["ctech_dirs"] == [str(d)]


# ---------------------------------------------------------------------------
# validate.*
# ---------------------------------------------------------------------------

def test_validate_ctech_directories_ok(tmp_path):
    d1 = tmp_path / "ctech1"; d1.mkdir()
    validate.validate_ctech_directories({"corimh": _die([], [str(d1)])})


def test_validate_ctech_directories_missing(tmp_path):
    with pytest.raises(FileNotFoundError):
        validate.validate_ctech_directories(
            {"corimh": _die([], [str(tmp_path / "nope")])}
        )


def test_validate_config_files_ok(tmp_path):
    cfg = _write(tmp_path / "a.cth", "")
    validate.validate_config_files({"corimh": _die([str(cfg)], [])})


def test_validate_config_files_missing(tmp_path):
    with pytest.raises(FileNotFoundError):
        validate.validate_config_files(
            {"corimh": _die([str(tmp_path / "missing.cth")], [])}
        )


def test_validate_config_files_none_listed(tmp_path):
    with pytest.raises(FileNotFoundError):
        validate.validate_config_files({"corimh": _die([], [])})


def test_validate_output_writable_ok(tmp_path):
    validate.validate_output_writable(str(tmp_path / "prep_tech"))


def test_validate_output_writable_fails(tmp_path):
    ro = tmp_path / "ro"
    ro.mkdir()
    ro.chmod(0o500)
    try:
        with pytest.raises(PermissionError):
            validate.validate_output_writable(str(ro / "prep_tech"))
    finally:
        ro.chmod(0o700)


def test_pre_flight_validation_ok(tmp_path):
    ctech = tmp_path / "ctech"; ctech.mkdir()
    cfg = _write(tmp_path / "a.cth", "")
    dies = {"corimh": _die([str(cfg)], [str(ctech)])}
    validate.pre_flight_validation(dies, str(tmp_path / "prep_tech"))


def test_pre_flight_validation_raises_missing_ctech(tmp_path):
    cfg = _write(tmp_path / "a.cth", "")
    dies = {"corimh": _die([str(cfg)], [str(tmp_path / "nope")])}
    with pytest.raises(FileNotFoundError):
        validate.pre_flight_validation(dies, str(tmp_path / "prep_tech"))
