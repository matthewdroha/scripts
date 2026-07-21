import os

import pytest

from prep_tech import discover


def _write(path, text):
    with open(path, "w") as f:
        f.write(text)
    return path


# ---------------------------------------------------------------------------
# .cth parsing + DesignPackage resolution
# ---------------------------------------------------------------------------

def test_parse_cth_file_designpackage_only(tmp_path):
    cth = _write(
        tmp_path / "x.cth",
        "[HEADER]\n"
        "foo = bar\n"
        "[DESIGNPACKAGE]\n"
        "LIB_HEIGHT_CLASS = i0m_180h_50pp\n"
        "lib_name = i0m\n"
        "i0m = designpackage(name=1278.6,path)/lib786_i0m_180h_50pp\n"
        "path = /p/hdk/cad/dp/78p6/designpackage(name=1278.6,version)\n"
        "version = v1.0_2\n"
        "[ENVS]\n"
        "path = ignored\n",
    )
    params = discover.parse_cth_file(str(cth))
    assert params["lib_name"] == "i0m"
    assert params["version"] == "v1.0_2"
    # A key from a different section must not leak in.
    assert params["path"].endswith("designpackage(name=1278.6,version)")


def test_resolve_design_package_recursive():
    params = {
        "path": "/p/hdk/cad/dp/78p6/designpackage(name=1278.6,version)",
        "version": "v1.0_2",
    }
    value = "designpackage(name=1278.6,path)/lib786_i0m_180h_50pp"
    resolved = discover.resolve_design_package(value, params)
    assert resolved == "/p/hdk/cad/dp/78p6/v1.0_2/lib786_i0m_180h_50pp"


def test_resolve_design_package_missing_field():
    with pytest.raises(KeyError):
        discover.resolve_design_package("designpackage(name=x,nope)", {})


def test_resolve_lib_root_deref_then_tokens():
    # lib_name is a *key* that dereferences to another field.
    params = {
        "lib_name": "i0m",
        "i0m": "designpackage(name=1278.6,path)/lib786_i0m_180h_50pp",
        "path": "/p/hdk/cad/dp/78p6/designpackage(name=1278.6,version)",
        "version": "v1.0_2",
    }
    root = discover.resolve_lib_root(params)
    assert root == "/p/hdk/cad/dp/78p6/v1.0_2/lib786_i0m_180h_50pp"


def test_resolve_lib_root_uppercase_key():
    # Real g1i .cth uses UPPERCASE LIB_NAME and an already-resolved path.
    params = {
        "LIB_NAME": "g1i",
        "g1i": "/p/hdk/cad/stdcells/lib764_g1i_210h_50pp/pdk110_r6v2p1_fv",
    }
    root = discover.resolve_lib_root(params)
    assert root == "/p/hdk/cad/stdcells/lib764_g1i_210h_50pp/pdk110_r6v2p1_fv"


def test_resolve_lib_root_contour_discovery(tmp_path):
    # Contour .cth: no explicit <lib_name> field; discover under 'path' by
    # lib_name + pitch (from lib_height_class) + '_fv'.
    base = tmp_path / "76p5" / "v1.0_2"
    base.mkdir(parents=True)
    for d in [
        "lib765_g1i_210h_50pp_pdk10_r4v0p0_fv",
        "lib765_g1i_210h_50pp_pdk100_anamux",
        "lib765_g1m_240h_50pp_pdk10_r4v0p0_fv",
        "lib765_g1m_240h_100pp_pdk10_r4v0p0_fv",
    ]:
        (base / d).mkdir()

    g1i = discover.resolve_lib_root(
        {"lib_name": "g1i", "lib_height_class": "g1i_7dg_50pp", "path": str(base)}
    )
    assert g1i.endswith("lib765_g1i_210h_50pp_pdk10_r4v0p0_fv")

    # Pitch (50pp) disambiguates the two g1m _fv dirs.
    g1m = discover.resolve_lib_root(
        {"lib_name": "g1m", "lib_height_class": "g1m_8dg_50pp", "path": str(base)}
    )
    assert g1m.endswith("lib765_g1m_240h_50pp_pdk10_r4v0p0_fv")


def test_resolve_lib_root_contour_missing(tmp_path):
    base = tmp_path / "empty"
    base.mkdir()
    with pytest.raises(FileNotFoundError):
        discover.resolve_lib_root(
            {"lib_name": "g1i", "lib_height_class": "g1i_7dg_50pp",
             "path": str(base)}
        )



# ---------------------------------------------------------------------------
# ctech .sv parsing
# ---------------------------------------------------------------------------

def test_parse_ctech_sv(tmp_path):
    sv = _write(
        tmp_path / "ctech_lib_and.sv",
        "// header comment\n"
        "module ctech_lib_and (\n"
        "   input logic a,\n"
        "   output logic o );\n"
        "   g1iand002ab1n06x5 ctech_lib_and_dcszo (.a(a), .o(o));\n"
        "   wire w;\n"
        "   assign o = a;\n"
        "endmodule\n",
    )
    cell, insts = discover.parse_ctech_sv(str(sv))
    assert cell == "ctech_lib_and"
    assert "g1iand002ab1n06x5" in insts
    assert "wire" not in insts
    assert "assign" not in insts


def test_find_ctech_sv(tmp_path):
    _write(tmp_path / "ctech_lib_and.sv", "module ctech_lib_and; endmodule\n")
    _write(tmp_path / "ctech_lib_buf.sv", "module ctech_lib_buf; endmodule\n")
    _write(tmp_path / "CTECH_notes.hdl", "ignore\n")
    _write(tmp_path / "other.sv", "module other; endmodule\n")
    found = [os.path.basename(p) for p in discover.find_ctech_sv(str(tmp_path))]
    assert found == ["ctech_lib_and.sv", "ctech_lib_buf.sv"]


# ---------------------------------------------------------------------------
# bmod / bundle enumeration
# ---------------------------------------------------------------------------

def test_parse_bmod_cells(tmp_path):
    bmod = _write(
        tmp_path / "lib_base_lvt_bmod.v",
        "module g1iaboi22ab1d16x5 (a, y); endmodule\n"
        "module g1iand002ab1n06x5 (a, b, o); endmodule\n",
    )
    cells = discover.parse_bmod_cells(str(bmod))
    assert cells == {"g1iaboi22ab1d16x5", "g1iand002ab1n06x5"}


def test_enumerate_bundles(tmp_path):
    lib_root = tmp_path / "lib764_g1i_210h_50pp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    (bundle / "lib").mkdir()
    (bundle / "ndm").mkdir()
    # A non-bundle directory (no verilog/*bmod.v) must be skipped.
    (lib_root / "doc").mkdir()

    _write(
        bundle / "verilog" / "lib764_g1i_210h_50pp_base_lvt_bmod.v",
        "module g1iand002ab1n06x5 (a, b, o); endmodule\n",
    )
    _write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz", "")
    _write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb", "")
    _write(bundle / "ndm" / "lib764_g1i_210h_50pp_base_lvt.ndm", "")

    bundles = discover.enumerate_bundles(str(lib_root))
    assert set(bundles) == {"base_lvt"}
    bc = bundles["base_lvt"]
    assert "g1iand002ab1n06x5" in bc["cells"]
    assert bc["lib"] and bc["ldb"] and bc["ndm"]


# ---------------------------------------------------------------------------
# PVT + nldm selection
# ---------------------------------------------------------------------------

def test_select_nldm_prefers_target_pvt():
    files = [
        "d/lib_base_lvt_tttt_0p650v_100c_tttt_cmax_ccslnt.lib.gz",
        "d/lib_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
        "d/lib_base_lvt_rcss_0p550v_0c_pcss_cmax_nldm.lib.gz",
    ]
    sel = discover.select_nldm(files)
    assert os.path.basename(sel) == (
        "lib_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz"
    )


def test_select_nldm_none_when_no_nldm():
    assert discover.select_nldm(["d/x_ccslnt.lib.gz"]) is None


def test_select_nldm_handles_negative_temp():
    files = [
        "d/lib_tttt_0p650v_m40c_tttt_cmax_nldm.lib.gz",
        "d/lib_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
    ]
    sel = discover.select_nldm(files)
    assert "100c" in os.path.basename(sel)


def test_nldm_only_filter():
    files = ["a_nldm.lib.gz", "b_ccslnt.lib.gz", "c_nldm.ldb"]
    assert discover.nldm_only(files) == ["a_nldm.lib.gz", "c_nldm.ldb"]


# ---------------------------------------------------------------------------
# REGEX collateral filtering
# ---------------------------------------------------------------------------

def test_regex_filter_union_search():
    files = [
        "d/lib_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
        "d/lib_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.lib.gz",
        "d/lib_base_lvt_tttt_0p850v_100c_tttt_cmin_nldm.lib.gz",
    ]
    compiled = discover.compile_regexes([r"tttt\S+850v\S+100c\S+cmax"])
    out = discover.regex_filter(files, compiled)
    assert out == ["d/lib_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.lib.gz"]


def test_regex_filter_union_any():
    files = ["d/a_650v_x.lib.gz", "d/b_850v_x.lib.gz", "d/c_900v_x.lib.gz"]
    compiled = discover.compile_regexes([r"650v", r"850v"])
    out = discover.regex_filter(files, compiled)
    assert out == ["d/a_650v_x.lib.gz", "d/b_850v_x.lib.gz"]


def test_regex_filter_empty_patterns():
    assert discover.regex_filter(["a", "b"], []) == []


def test_compile_regexes_invalid():
    import re
    with pytest.raises(re.error):
        discover.compile_regexes(["("])
