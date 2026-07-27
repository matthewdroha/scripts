import pytest

from prep_tech import generate


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


@pytest.fixture
def fake_project(tmp_path):
    """A resolved lib tree + an absolute config file + a ctech dir.

    Returns (parsed, config_path, lib_root).
    """
    lib_root = tmp_path / "lib999_myp_180h_50pp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    (bundle / "lib").mkdir()
    (bundle / "ndm").mkdir()
    _write(
        bundle / "verilog" / "lib999_myp_180h_50pp_base_lvt_bmod.v",
        "module mycell000ab1n02x5 (a, o); endmodule\n",
    )
    _write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz", "")
    _write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_ccslnt.lib.gz", "")
    _write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb", "")
    _write(bundle / "ndm" / "lib999_myp_180h_50pp_base_lvt.ndm", "")

    cfg = tmp_path / "a.cth"
    _write(cfg, "[DESIGNPACKAGE]\nlib_name = myp\nmyp = " + str(lib_root) + "\n")

    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_x.sv",
        "module ctech_lib_x (input a, output o);\n"
        "   mycell000ab1n02x5 u0 (.a(a), .o(o));\n"
        "endmodule\n",
    )

    parsed = {"dies": {"corimh": _die([str(cfg)], [str(ctech)])}}
    return parsed, str(cfg), str(lib_root)


# ---------------------------------------------------------------------------
# build_die_plan
# ---------------------------------------------------------------------------

def test_build_die_plan(fake_project):
    parsed, cfg, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])

    assert plan["referenced_keys"] == {"base_lvt"}
    assert plan["ctech_cells"] == {"ctech_lib_x"}
    assert len(plan["refs"]) == 1
    ctech_cell, stdcell, bundle, vpath, svpath, config = plan["refs"][0]
    assert ctech_cell == "ctech_lib_x"
    assert stdcell == "mycell000ab1n02x5"
    assert bundle == "base_lvt"
    assert vpath.endswith("base_lvt_bmod.v")
    assert svpath.endswith("ctech_lib_x.sv")
    assert config == cfg          # absolute configuration path


# ---------------------------------------------------------------------------
# render_die_files
# ---------------------------------------------------------------------------

def test_render_die_files(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    files = generate.render_die_files(plan)

    static = files["static_stdcells.f"]
    assert static.splitlines()[0] == "+define+functional"
    assert "base_lvt_bmod.v" in static

    lib_ctech = files["stdcell.lib.list.ctech"]
    assert "_nldm.lib.gz" in lib_ctech
    assert "ccslnt" not in lib_ctech

    lib_full = files["stdcell.lib.list"]
    assert "ccslnt" not in lib_full
    assert "_nldm.lib.gz" in lib_full

    assert "base_lvt.ndm" in files["stdcell.ndm.list"]
    assert files["stdcell.ldb.list.ctech"].strip().endswith("_nldm.ldb")


# ---------------------------------------------------------------------------
# render_report / render_csv
# ---------------------------------------------------------------------------

def test_render_report(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    report = generate.render_report([("corimh", plan)])
    assert "# script: prep_tech" in report
    assert "# generated:" in report
    summary = generate.die_summary("corimh", plan)
    assert summary in report
    assert report.index(summary) < report.index("die: corimh")
    assert "die: corimh" in report
    assert "ctech cells found: 1" in report
    assert "referenced stdcells (deduplicated): 1" in report
    assert "unresolved stdcell instantiations: 0" in report


def test_render_csv_columns(fake_project):
    parsed, cfg, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    csv = generate.render_csv([("corimh", plan)])
    lines = csv.splitlines()
    assert lines[0] == (
        "die,ctech_cell,stdcell name,stdcell library,"
        "path to configuration file,path to stdcell verilog,"
        "path to ctech verilog"
    )
    row = lines[1]
    # die, ctech_cell, stdcell, bundle, config, ...
    assert row.startswith(
        f"corimh,ctech_lib_x,mycell000ab1n02x5,base_lvt,{cfg},"
    )
    assert row.endswith("ctech_lib_x.sv")


def test_unresolved_stdcell_reported(tmp_path):
    lib_root = tmp_path / "lib_myp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    _write(
        bundle / "verilog" / "lib_myp_base_lvt_bmod.v",
        "module mypand000ab1n02x5 (a, o); endmodule\n",
    )
    cfg = tmp_path / "a.cth"
    _write(cfg, "[DESIGNPACKAGE]\nlib_name = myp\nmyp = " + str(lib_root) + "\n")
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_y.sv",
        "module ctech_lib_y (input a, output o);\n"
        "   mypand000ab1n02x5 u0 (.a(a), .o(o));\n"
        "   mypmissing0ab1n02x5 u1 (.a(a), .o(o));\n"
        "   some_submodule u2 (.a(a), .o(o));\n"
        "endmodule\n",
    )

    plan = generate.build_die_plan("corcbbp", _die([str(cfg)], [str(ctech)]))
    unresolved = plan["unresolved"]
    assert len(unresolved) == 1
    ctech_cell, stdcell, sv = unresolved[0]
    assert ctech_cell == "ctech_lib_y"
    assert stdcell == "mypmissing0ab1n02x5"
    assert sv.endswith("ctech_lib_y.sv")

    report = generate.render_report([("corcbbp", plan)])
    assert "unresolved stdcell instantiations: 1" in report
    assert "mypmissing0ab1n02x5 <- ctech_lib_y" in report


# ---------------------------------------------------------------------------
# generate_all (end to end)
# ---------------------------------------------------------------------------

def test_generate_all_writes_tree(fake_project, tmp_path):
    parsed, _, _ = fake_project
    out_root = tmp_path / "out" / "prep_tech"
    written, plans, has_dupes = generate.generate_all(parsed, str(out_root))

    assert (out_root / "corimh" / "static_stdcells.f").is_file()
    assert (out_root / "corimh" / "stdcell.ndm.list").is_file()
    assert (out_root / "prep_tech.report").is_file()
    assert (out_root / "prep_tech.csv").is_file()
    assert (out_root / "prep_tech.duplicates.csv").is_file()
    assert has_dupes is False
    # 6 die files + report + duplicates.csv + csv.
    assert len(written) == 9
    assert len(plans) == 1


def test_generate_all_empty_dies(tmp_path):
    out = tmp_path / "explicit_root"
    parsed = {"dies": {}}
    written, plans, has_dupes = generate.generate_all(parsed, str(out))
    assert (out / "prep_tech.report").is_file()
    assert (out / "prep_tech.csv").is_file()
    assert (out / "prep_tech.duplicates.csv").is_file()
    assert plans == []
    assert has_dupes is False


# ---------------------------------------------------------------------------
# REGEX-filtered lists
# ---------------------------------------------------------------------------

@pytest.fixture
def regex_project(tmp_path):
    """Project with 650mV and 850mV nldm corners + a REGEX targeting 850mV."""
    lib_root = tmp_path / "lib_myp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    (bundle / "lib").mkdir()
    (bundle / "ndm").mkdir()
    _write(
        bundle / "verilog" / "lib_myp_base_lvt_bmod.v",
        "module mypand000ab1n02x5 (a, o); endmodule\n",
    )
    L = bundle / "lib"
    _write(L / "myp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz", "")
    _write(L / "myp_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.lib.gz", "")
    _write(L / "myp_base_lvt_tttt_0p850v_100c_tttt_cmax_ccslnt.lib.gz", "")
    _write(L / "myp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb", "")
    _write(L / "myp_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.ldb", "")
    _write(bundle / "ndm" / "myp_base_lvt.ndm", "")

    cfg = tmp_path / "a.cth"
    _write(cfg, "[DESIGNPACKAGE]\nlib_name = myp\nmyp = " + str(lib_root) + "\n")
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_x.sv",
        "module ctech_lib_x (input a, output o);\n"
        "   mypand000ab1n02x5 u0 (.a(a), .o(o));\n"
        "endmodule\n",
    )
    parsed = {
        "dies": {
            "corimh": _die(
                [str(cfg)], [str(ctech)],
                regexes=[r"tttt\S+850v\S+100c\S+cmax"],
            )
        }
    }
    return parsed


def test_regex_list_files_rendered(regex_project):
    plan = generate.build_die_plan("corimh", regex_project["dies"]["corimh"])
    files = generate.render_die_files(plan)

    assert "0p650v" in files["stdcell.lib.list.ctech"]
    rgx = files["stdcell.lib.list.ctech.regex"]
    assert "0p850v" in rgx
    assert "0p650v" not in rgx
    assert "ccslnt" not in rgx
    assert files["stdcell.ldb.list.ctech.regex"].strip().endswith(
        "0p850v_100c_tttt_cmax_nldm.ldb"
    )


def test_regex_report_counts(regex_project):
    plan = generate.build_die_plan("corimh", regex_project["dies"]["corimh"])
    report = generate.render_report([("corimh", plan)])
    assert "ctech-referenced .lib files: 1" in report
    assert "regex-filtered .lib files: 1" in report
    assert "regex-filtered .ldb/.db files: 1" in report
    assert "full-list .lib files:" in report


def test_no_regex_no_regex_files(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    files = generate.render_die_files(plan)
    assert "stdcell.lib.list.ctech.regex" not in files
    assert "stdcell.ldb.list.ctech.regex" not in files
    report = generate.render_report([("corimh", plan)])
    assert "regex-filtered" not in report


# ---------------------------------------------------------------------------
# Configuration-file precedence (spec 2.1): first listed config wins
# ---------------------------------------------------------------------------

def _lib_with_cell(tmp_path, tag, bundle_name, cell):
    lib_root = tmp_path / f"lib_{tag}_pdk"
    bundle = lib_root / bundle_name
    (bundle / "verilog").mkdir(parents=True)
    _write(
        bundle / "verilog" / f"lib_{tag}_{bundle_name}_bmod.v",
        f"module {cell} (a, o); endmodule\n",
    )
    return lib_root


def test_config_precedence_first_wins(tmp_path):
    lib_a = _lib_with_cell(tmp_path, "a", "base_lvt", "dupcell000ab1n02x5")
    lib_b = _lib_with_cell(tmp_path, "b", "base_lvt", "dupcell000ab1n02x5")
    cfg_a = _write(tmp_path / "a.cth",
                   "[DESIGNPACKAGE]\nlib_name = a\na = " + str(lib_a) + "\n")
    cfg_b = _write(tmp_path / "b.cth",
                   "[DESIGNPACKAGE]\nlib_name = b\nb = " + str(lib_b) + "\n")
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_x.sv",
        "module ctech_lib_x (input a, output o);\n"
        "   dupcell000ab1n02x5 u0 (.a(a), .o(o));\n"
        "endmodule\n",
    )

    die_info = _die([str(cfg_a), str(cfg_b)], [str(ctech)])
    plan = generate.build_die_plan("d", die_info)
    assert len(plan["refs"]) == 1
    _, stdcell, _, vpath, _, config = plan["refs"][0]
    assert stdcell == "dupcell000ab1n02x5"
    assert str(lib_a) in vpath
    assert str(lib_b) not in vpath
    assert config == str(cfg_a)

    die_info["config_files"] = [str(cfg_b), str(cfg_a)]
    plan2 = generate.build_die_plan("d", die_info)
    assert str(lib_b) in plan2["refs"][0][3]
    assert plan2["refs"][0][5] == str(cfg_b)


# ---------------------------------------------------------------------------
# Duplicate stdcell definitions across configuration files (spec 2.1 / 3.5)
# ---------------------------------------------------------------------------

def _dup_project(tmp_path, bundle_a="base_lvt", bundle_b="base_lvt"):
    lib_a = _lib_with_cell(tmp_path, "a", bundle_a, "dupcell000ab1n02x5")
    lib_b = _lib_with_cell(tmp_path, "b", bundle_b, "dupcell000ab1n02x5")
    cfg_a = _write(tmp_path / "a.cth",
                   "[DESIGNPACKAGE]\nlib_name = a\na = " + str(lib_a) + "\n")
    cfg_b = _write(tmp_path / "b.cth",
                   "[DESIGNPACKAGE]\nlib_name = b\nb = " + str(lib_b) + "\n")
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(ctech / "ctech_lib_x.sv", "module ctech_lib_x; endmodule\n")
    parsed = {"dies": {"d": _die([str(cfg_a), str(cfg_b)], [str(ctech)])}}
    return parsed, str(cfg_a), str(cfg_b)


def test_duplicate_detected_same_bundle(tmp_path):
    parsed, cfg_a, cfg_b = _dup_project(tmp_path)
    plan = generate.build_die_plan("d", parsed["dies"]["d"])
    assert plan["duplicates"] == [
        ("dupcell000ab1n02x5", "base_lvt", f"{cfg_a}:{cfg_b}")
    ]


def test_duplicate_detected_regardless_of_bundle(tmp_path):
    parsed, cfg_a, cfg_b = _dup_project(
        tmp_path, bundle_a="base_lvt", bundle_b="clk_lvt"
    )
    plan = generate.build_die_plan("d", parsed["dies"]["d"])
    cell, bundles, cfgs = plan["duplicates"][0]
    assert cell == "dupcell000ab1n02x5"
    assert bundles == "base_lvt:clk_lvt"
    assert cfgs == f"{cfg_a}:{cfg_b}"


def test_duplicates_csv_header_only_when_none(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    csv = generate.render_duplicates_csv([("corimh", plan)])
    assert csv == "die,stdcell library,stdcell name,configuration file list\n"


def test_generate_all_fatal_on_duplicates(tmp_path):
    parsed, cfg_a, cfg_b = _dup_project(tmp_path)
    out = tmp_path / "out"
    written, plans, has_dupes = generate.generate_all(
        parsed, str(out), allow_duplicates=False
    )
    assert has_dupes is True
    assert (out / "prep_tech.report").is_file()
    assert (out / "prep_tech.duplicates.csv").is_file()
    assert not (out / "prep_tech.csv").exists()
    assert not (out / "d").exists()
    dup = (out / "prep_tech.duplicates.csv").read_text()
    assert f"d,base_lvt,dupcell000ab1n02x5,{cfg_a}:{cfg_b}" in dup


def test_generate_all_allow_duplicates(tmp_path):
    parsed, _, _ = _dup_project(tmp_path)
    out = tmp_path / "out"
    written, plans, has_dupes = generate.generate_all(
        parsed, str(out), allow_duplicates=True
    )
    assert has_dupes is True
    assert (out / "prep_tech.csv").is_file()
    assert (out / "d" / "static_stdcells.f").is_file()
    assert (out / "prep_tech.duplicates.csv").read_text().count("\n") >= 2
