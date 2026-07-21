import os

import pytest

from prep_tech import generate


def _write(path, text):
    with open(path, "w") as f:
        f.write(text)
    return path


@pytest.fixture
def fake_project(tmp_path):
    """Build a minimal cheetah backend + resolved lib tree + ctech dir.

    Returns (parsed, cheetah_backend, lib_root).
    """
    # --- resolved stdcell library root with one bundle ---
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

    # --- cheetah backend with a .cth pointing at lib_root ---
    backend = tmp_path / "backend"
    backend.mkdir()
    _write(
        backend / "a.cth",
        "[DESIGNPACKAGE]\n"
        "lib_name = mylib\n"
        f"mylib = {lib_root}\n",
    )

    # --- ctech dir referencing the stdcell ---
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_x.sv",
        "module ctech_lib_x (input a, output o);\n"
        "   mycell000ab1n02x5 u0 (.a(a), .o(o));\n"
        "endmodule\n",
    )

    parsed = {
        "cheetah_backend": str(backend),
        "dies": {
            "corimh": {"cth_files": ["a.cth"], "ctech_dirs": [str(ctech)]},
        },
    }
    return parsed, str(backend), str(lib_root)


# ---------------------------------------------------------------------------
# build_die_plan
# ---------------------------------------------------------------------------

def test_build_die_plan(fake_project):
    parsed, backend, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)

    assert plan["referenced_keys"] == {"base_lvt"}
    assert plan["ctech_cells"] == {"ctech_lib_x"}
    assert len(plan["refs"]) == 1
    ctech_cell, stdcell, bundle, vpath, svpath, cth = plan["refs"][0]
    assert ctech_cell == "ctech_lib_x"
    assert stdcell == "mycell000ab1n02x5"
    assert bundle == "base_lvt"
    assert vpath.endswith("base_lvt_bmod.v")
    assert svpath.endswith("ctech_lib_x.sv")
    assert cth == "a.cth"


# ---------------------------------------------------------------------------
# render_die_files
# ---------------------------------------------------------------------------

def test_render_die_files(fake_project):
    parsed, backend, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    files = generate.render_die_files(plan)

    static = files["static_stdcells.f"]
    assert static.splitlines()[0] == "+define+functional"
    assert "base_lvt_bmod.v" in static

    lib_ctech = files["stdcell.lib.list.ctech"]
    assert "_nldm.lib.gz" in lib_ctech
    assert "ccslnt" not in lib_ctech

    # Full lib list is nldm-only.
    lib_full = files["stdcell.lib.list"]
    assert "ccslnt" not in lib_full
    assert "_nldm.lib.gz" in lib_full

    assert "base_lvt.ndm" in files["stdcell.ndm.list"]
    assert files["stdcell.ldb.list.ctech"].strip().endswith("_nldm.ldb")


# ---------------------------------------------------------------------------
# render_report / render_csv
# ---------------------------------------------------------------------------

def test_render_report(fake_project):
    parsed, backend, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    report = generate.render_report([("corimh", plan)])
    # Header: script name + generation timestamp.
    assert "# script: prep_tech" in report
    assert "# generated:" in report
    # Top summary line, identical to die_summary / STDOUT.
    summary = generate.die_summary("corimh", plan)
    assert summary in report
    assert report.index(summary) < report.index("die: corimh")  # at the top
    assert "die: corimh" in report
    assert "ctech cells found: 1" in report
    assert "referenced stdcells (deduplicated): 1" in report
    assert "unresolved stdcell instantiations: 0" in report


def test_unresolved_stdcell_reported(tmp_path):
    # lib_name prefix is "myp"; the bundle defines mypand000 but the ctech
    # also instantiates mypmissing0 (prefix match, no definition) and a
    # non-stdcell submodule token (no prefix match -> not flagged).
    lib_root = tmp_path / "lib_myp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    _write(
        bundle / "verilog" / "lib_myp_base_lvt_bmod.v",
        "module mypand000ab1n02x5 (a, o); endmodule\n",
    )

    backend = tmp_path / "backend"
    backend.mkdir()
    _write(
        backend / "a.cth",
        "[DESIGNPACKAGE]\nlib_name = myp\nmyp = " + str(lib_root) + "\n",
    )

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

    die_info = {"cth_files": ["a.cth"], "ctech_dirs": [str(ctech)]}
    plan = generate.build_die_plan("corcbbp", die_info, str(backend))

    unresolved = plan["unresolved"]
    assert len(unresolved) == 1
    ctech_cell, stdcell, sv = unresolved[0]
    assert ctech_cell == "ctech_lib_y"
    assert stdcell == "mypmissing0ab1n02x5"
    assert sv.endswith("ctech_lib_y.sv")

    report = generate.render_report([("corcbbp", plan)])
    assert "unresolved stdcell instantiations: 1" in report
    assert "mypmissing0ab1n02x5 <- ctech_lib_y" in report



def test_render_csv_has_ctech_verilog_column(fake_project):
    parsed, backend, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    csv = generate.render_csv([("corimh", plan)])
    lines = csv.splitlines()
    assert lines[0] == (
        "die,ctech_cell,stdcell name,.cth file,stdcell library,"
        "path to stdcell verilog,path to ctech verilog"
    )
    row = lines[1]
    assert row.startswith(
        "corimh,ctech_lib_x,mycell000ab1n02x5,a.cth,base_lvt,"
    )
    assert row.endswith("ctech_lib_x.sv")


# ---------------------------------------------------------------------------
# generate_all (end to end)
# ---------------------------------------------------------------------------

def test_generate_all_writes_tree(fake_project, tmp_path):
    parsed, backend, _ = fake_project
    out_root = tmp_path / "out" / "prep_tech"
    written, plans, has_dupes = generate.generate_all(
        parsed, backend, str(out_root)
    )

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
    # With no dies, only the report, duplicates.csv, and csv are written.
    out = tmp_path / "explicit_root"
    parsed = {"cheetah_backend": str(tmp_path), "dies": {}}
    written, plans, has_dupes = generate.generate_all(
        parsed, str(tmp_path), str(out)
    )
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

    backend = tmp_path / "backend"
    backend.mkdir()
    _write(
        backend / "a.cth",
        "[DESIGNPACKAGE]\nlib_name = myp\nmyp = " + str(lib_root) + "\n",
    )
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_x.sv",
        "module ctech_lib_x (input a, output o);\n"
        "   mypand000ab1n02x5 u0 (.a(a), .o(o));\n"
        "endmodule\n",
    )
    parsed = {
        "cheetah_backend": str(backend),
        "dies": {
            "corimh": {
                "cth_files": ["a.cth"],
                "ctech_dirs": [str(ctech)],
                "regexes": [r"tttt\S+850v\S+100c\S+cmax"],
            }
        },
    }
    return parsed, str(backend)


def test_regex_list_files_rendered(regex_project):
    parsed, backend = regex_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    files = generate.render_die_files(plan)

    # Base .ctech list selects the 650mV nldm (closest to target).
    assert "0p650v" in files["stdcell.lib.list.ctech"]

    # Regex list keeps the 850mV nldm only (nldm AND regex; ccslnt excluded).
    rgx = files["stdcell.lib.list.ctech.regex"]
    assert "0p850v" in rgx
    assert "0p650v" not in rgx
    assert "ccslnt" not in rgx
    assert files["stdcell.ldb.list.ctech.regex"].strip().endswith(
        "0p850v_100c_tttt_cmax_nldm.ldb"
    )


def test_regex_report_counts(regex_project):
    parsed, backend = regex_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    report = generate.render_report([("corimh", plan)])
    assert "ctech-referenced .lib files: 1" in report
    assert "regex-filtered .lib files: 1" in report
    assert "regex-filtered .ldb/.db files: 1" in report
    assert "full-list .lib files:" in report


def test_no_regex_no_regex_files(fake_project):
    parsed, backend, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    files = generate.render_die_files(plan)
    assert "stdcell.lib.list.ctech.regex" not in files
    assert "stdcell.ldb.list.ctech.regex" not in files
    # And the report omits the regex-filtered lines.
    report = generate.render_report([("corimh", plan)])
    assert "regex-filtered" not in report


# ---------------------------------------------------------------------------
# .cth precedence (spec 2.1): first listed .cth wins for duplicate cells
# ---------------------------------------------------------------------------

def _lib_with_dupcell(tmp_path, tag):
    """Build a lib root whose base_lvt bundle defines the shared dup cell."""
    lib_root = tmp_path / f"lib_{tag}_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    _write(
        bundle / "verilog" / f"lib_{tag}_base_lvt_bmod.v",
        "module dupcell000ab1n02x5 (a, o); endmodule\n",
    )
    return lib_root


def test_cth_precedence_first_wins(tmp_path):
    lib_a = _lib_with_dupcell(tmp_path, "a")
    lib_b = _lib_with_dupcell(tmp_path, "b")

    backend = tmp_path / "backend"
    backend.mkdir()
    _write(backend / "a.cth", "[DESIGNPACKAGE]\nlib_name = a\na = " + str(lib_a) + "\n")
    _write(backend / "b.cth", "[DESIGNPACKAGE]\nlib_name = b\nb = " + str(lib_b) + "\n")

    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(
        ctech / "ctech_lib_x.sv",
        "module ctech_lib_x (input a, output o);\n"
        "   dupcell000ab1n02x5 u0 (.a(a), .o(o));\n"
        "endmodule\n",
    )

    # a.cth listed first -> highest precedence.
    die_info = {
        "cth_files": ["a.cth", "b.cth"],
        "ctech_dirs": [str(ctech)],
        "regexes": [],
    }
    plan = generate.build_die_plan("d", die_info, str(backend))
    assert len(plan["refs"]) == 1
    _, stdcell, _, vpath, _, cth = plan["refs"][0]
    assert stdcell == "dupcell000ab1n02x5"
    assert str(lib_a) in vpath          # resolved to the first .cth's library
    assert str(lib_b) not in vpath
    assert cth == "a.cth"               # contributing .cth is the first listed

    # Reverse the order -> the other library wins.
    die_info["cth_files"] = ["b.cth", "a.cth"]
    plan2 = generate.build_die_plan("d", die_info, str(backend))
    assert str(lib_b) in plan2["refs"][0][3]
    assert plan2["refs"][0][5] == "b.cth"


# ---------------------------------------------------------------------------
# Duplicate stdcell definitions across .cth files (spec 2.1 / 3.4b)
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


def _dup_project(tmp_path, bundle_a="base_lvt", bundle_b="base_lvt"):
    lib_a = _lib_with_cell(tmp_path, "a", bundle_a, "dupcell000ab1n02x5")
    lib_b = _lib_with_cell(tmp_path, "b", bundle_b, "dupcell000ab1n02x5")
    backend = tmp_path / "backend"
    backend.mkdir()
    _write(backend / "a.cth", "[DESIGNPACKAGE]\nlib_name = a\na = " + str(lib_a) + "\n")
    _write(backend / "b.cth", "[DESIGNPACKAGE]\nlib_name = b\nb = " + str(lib_b) + "\n")
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    _write(ctech / "ctech_lib_x.sv", "module ctech_lib_x; endmodule\n")
    parsed = {
        "cheetah_backend": str(backend),
        "dies": {
            "d": {
                "cth_files": ["a.cth", "b.cth"],
                "ctech_dirs": [str(ctech)],
                "regexes": [],
            }
        },
    }
    return parsed, str(backend)


def test_duplicate_detected_same_bundle(tmp_path):
    parsed, backend = _dup_project(tmp_path)
    plan = generate.build_die_plan("d", parsed["dies"]["d"], backend)
    assert plan["duplicates"] == [
        ("dupcell000ab1n02x5", "base_lvt", "a.cth:b.cth")
    ]


def test_duplicate_detected_regardless_of_bundle(tmp_path):
    parsed, backend = _dup_project(tmp_path, bundle_a="base_lvt", bundle_b="clk_lvt")
    plan = generate.build_die_plan("d", parsed["dies"]["d"], backend)
    cell, bundles, cths = plan["duplicates"][0]
    assert cell == "dupcell000ab1n02x5"
    assert bundles == "base_lvt:clk_lvt"   # union of bundle names
    assert cths == "a.cth:b.cth"


def test_duplicates_csv_header_only_when_none(fake_project):
    parsed, backend, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"], backend)
    csv = generate.render_duplicates_csv([("corimh", plan)])
    assert csv == "die,stdcell library,stdcell name,.cth file list\n"


def test_generate_all_fatal_on_duplicates(tmp_path):
    parsed, backend = _dup_project(tmp_path)
    out = tmp_path / "out"
    written, plans, has_dupes = generate.generate_all(
        parsed, backend, str(out), allow_duplicates=False
    )
    assert has_dupes is True
    # Report + duplicates.csv written; list-file tree + prep_tech.csv NOT.
    assert (out / "prep_tech.report").is_file()
    assert (out / "prep_tech.duplicates.csv").is_file()
    assert not (out / "prep_tech.csv").exists()
    assert not (out / "d").exists()
    # Duplicates CSV has the data row.
    dup = (out / "prep_tech.duplicates.csv").read_text()
    assert "d,base_lvt,dupcell000ab1n02x5,a.cth:b.cth" in dup


def test_generate_all_allow_duplicates(tmp_path):
    parsed, backend = _dup_project(tmp_path)
    out = tmp_path / "out"
    written, plans, has_dupes = generate.generate_all(
        parsed, backend, str(out), allow_duplicates=True
    )
    assert has_dupes is True
    # With override, the full tree IS written.
    assert (out / "prep_tech.csv").is_file()
    assert (out / "d" / "static_stdcells.f").is_file()
    assert (out / "prep_tech.duplicates.csv").read_text().count("\n") >= 2


