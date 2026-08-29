"""prep_tech.validate: pre-flight checks (spec 2.4)."""

import pytest

from prep_tech import validate


def test_validate_ctech_directories_ok(tmp_path, die):
    d1 = tmp_path / "ctech1"
    d1.mkdir()
    validate.validate_ctech_directories({"corimh": die([], [d1])})


def test_validate_ctech_directories_missing(tmp_path, die):
    with pytest.raises(FileNotFoundError):
        validate.validate_ctech_directories(
            {"corimh": die([], [tmp_path / "nope"])}
        )


def test_validate_config_files_ok(tmp_path, die, write):
    cfg = write(tmp_path / "a.cth", "")
    validate.validate_config_files({"corimh": die([cfg], [])})


def test_validate_config_files_missing(tmp_path, die):
    with pytest.raises(FileNotFoundError):
        validate.validate_config_files(
            {"corimh": die([tmp_path / "missing.cth"], [])}
        )


def test_validate_config_files_none_listed(die):
    with pytest.raises(FileNotFoundError):
        validate.validate_config_files({"corimh": die([], [])})


def test_validate_missing_paths(tmp_path, die):
    info = die([], [])
    info["missing"] = [str(tmp_path / "gone")]
    with pytest.raises(FileNotFoundError):
        validate.validate_missing_paths({"corimh": info})


def test_validate_regexes_invalid(die):
    with pytest.raises(ValueError):
        validate.validate_regexes({"corimh": die([], [], regexes=["("])})


def test_validate_output_writable_ok(tmp_path):
    validate.validate_output_writable(str(tmp_path / "prep_tech"))


def test_validate_output_writable_fails(tmp_path):
    read_only = tmp_path / "ro"
    read_only.mkdir()
    read_only.chmod(0o500)
    try:
        with pytest.raises(PermissionError):
            validate.validate_output_writable(str(read_only / "prep_tech"))
    finally:
        read_only.chmod(0o700)


def test_pre_flight_validation_ok(tmp_path, die, write):
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    cfg = write(tmp_path / "a.cth", "")
    dies = {"corimh": die([cfg], [ctech])}
    validate.pre_flight_validation(dies, str(tmp_path / "prep_tech"))


def test_pre_flight_validation_raises_missing_ctech(tmp_path, die, write):
    cfg = write(tmp_path / "a.cth", "")
    dies = {"corimh": die([cfg], [tmp_path / "nope"])}
    with pytest.raises(FileNotFoundError):
        validate.pre_flight_validation(dies, str(tmp_path / "prep_tech"))
