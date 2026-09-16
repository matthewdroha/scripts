"""prep_tech.cli: argument handling, preflight exit codes, dry-run, full run."""

from prep_tech import cli

from conftest import make_config, make_ctech, make_lib, write_text


def _input_md(tmp_path, regex=None):
    """Build a real input markdown file plus the tree it points at."""
    lib_root = tmp_path / "lib999_myp_pdk"
    make_lib(
        lib_root,
        "base_lvt",
        "mypand000ab1n02x5",
        corners=[
            "myp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
            "myp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb",
        ],
    )
    cfg = make_config(tmp_path / "a.cth", "myp", lib_root)
    ctech = make_ctech(tmp_path / "ctech", "ctech_lib_x", ["mypand000ab1n02x5"])
    suffix = f'  REGEX=r"{regex}"' if regex else ""
    return write_text(
        tmp_path / "prep_tech.input.md",
        f"## CORIMH DIE\n{ctech}\n{cfg}{suffix}\n",
    )


def test_help_lists_the_standard_flags(capsys):
    parser = cli.build_parser()
    text = parser.format_help()
    for flag in ["--dry-run", "--force", "--verbose", "--check", "--allow-duplicates"]:
        assert flag in text


def test_missing_input_file_is_preflight_failure(tmp_path, capsys):
    code = cli.main([str(tmp_path / "nope.md")])
    assert code == cli.EXIT_PREFLIGHT
    assert "input file not found" in capsys.readouterr().err


def test_missing_ctech_dir_is_preflight_failure(tmp_path, capsys):
    md = write_text(
        tmp_path / "in.md", f"## D DIE\n{tmp_path / 'ghost'}\n"
    )
    code = cli.main([md, "--output-root", str(tmp_path / "out")])
    assert code == cli.EXIT_PREFLIGHT
    assert "does not exist" in capsys.readouterr().err


def test_check_writes_nothing(tmp_path, capsys):
    md = _input_md(tmp_path)
    out = tmp_path / "out"
    assert cli.main([md, "--check", "--output-root", str(out)]) == cli.EXIT_OK
    assert "OK" in capsys.readouterr().out
    assert not out.exists()


def test_dry_run_writes_nothing(tmp_path, capsys):
    md = _input_md(tmp_path)
    out = tmp_path / "out"
    assert cli.main([md, "--dry-run", "--output-root", str(out)]) == cli.EXIT_OK
    stdout = capsys.readouterr().out
    assert "would write:" in stdout
    assert "corimh/static_stdcells.f" in stdout
    assert not out.exists()


def test_full_run_writes_tree(tmp_path, capsys):
    md = _input_md(tmp_path)
    out = tmp_path / "out"
    assert cli.main([md, "--output-root", str(out)]) == cli.EXIT_OK
    assert (out / "corimh" / "static_stdcells.f").is_file()
    assert (out / "prep_tech.report").is_file()
    assert "wrote 11 files" in capsys.readouterr().out


def test_regex_run_emits_regex_lists(tmp_path):
    md = _input_md(tmp_path, regex=r"tttt\S+650v\S+100c")
    out = tmp_path / "out"
    assert cli.main([md, "--output-root", str(out)]) == cli.EXIT_OK
    assert (out / "corimh" / "stdcell.lib.list.ctech.all.regex").is_file()
    assert (out / "corimh" / "stdcell.lib.list.all.regex").is_file()
    assert (out / "corimh" / "stdcell.ldb.list.all.regex").is_file()


def test_verbose_logs_progress(tmp_path, capsys):
    md = _input_md(tmp_path)
    cli.main([md, "--output-root", str(tmp_path / "out"), "--verbose"])
    assert "prep_tech: writing corimh/" in capsys.readouterr().out


def test_output_root_defaults_to_workarea(tmp_path, monkeypatch):
    monkeypatch.setenv("WORKAREA", str(tmp_path / "wa"))
    (tmp_path / "wa").mkdir()
    md = _input_md(tmp_path)
    assert cli.main([md]) == cli.EXIT_OK
    assert (tmp_path / "wa" / "prep_tech" / "prep_tech.report").is_file()


def test_output_root_defaults_to_cwd(tmp_path, monkeypatch):
    monkeypatch.delenv("WORKAREA", raising=False)
    md = _input_md(tmp_path)
    cwd = tmp_path / "cwd"
    cwd.mkdir()
    monkeypatch.chdir(cwd)
    assert cli.main([md]) == cli.EXIT_OK
    assert (cwd / "prep_tech" / "prep_tech.report").is_file()


def test_duplicates_exit_code(tmp_path, capsys):
    lib_a = tmp_path / "lib999_a_pdk"
    lib_b = tmp_path / "lib999_b_pdk"
    make_lib(lib_a, "base_lvt", "dupcell000ab1n02x5")
    make_lib(lib_b, "base_lvt", "dupcell000ab1n02x5")
    cfg_a = make_config(tmp_path / "a.cth", "a", lib_a)
    cfg_b = make_config(tmp_path / "b.cth", "b", lib_b)
    ctech = make_ctech(tmp_path / "ctech", "ctech_lib_x", ["dupcell000ab1n02x5"])
    md = write_text(
        tmp_path / "in.md", f"## D DIE\n{ctech}\n{cfg_a}\n{cfg_b}\n"
    )
    out = tmp_path / "out"

    assert cli.main([md, "--output-root", str(out)]) == cli.EXIT_DUPLICATES
    assert "duplicate stdcell definitions found" in capsys.readouterr().err

    assert cli.main([md, "--output-root", str(out), "--allow-duplicates"]) == (
        cli.EXIT_OK
    )
    assert (out / "d" / "static_stdcells.f").is_file()
