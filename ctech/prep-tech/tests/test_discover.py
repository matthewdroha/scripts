"""prep_tech.discover: configuration resolution, parsing, enumeration, selection."""

import gzip
import os
import re

import pytest

from prep_tech import discover


# ---------------------------------------------------------------------------
# Configuration parsing + DesignPackage resolution (spec 2.3)
# ---------------------------------------------------------------------------

def test_parse_cth_file_designpackage_only(tmp_path, write):
    cth = write(
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
    params = discover.parse_cth_file(cth)
    assert params["lib_name"] == "i0m"
    assert params["version"] == "v1.0_2"
    assert "foo" not in params
    assert params["path"].endswith("designpackage(name=1278.6,version)")


def test_resolve_design_package_recursive():
    params = {
        "path": "/p/hdk/cad/dp/78p6/designpackage(name=1278.6,version)",
        "version": "v1.0_2",
    }
    resolved = discover.resolve_design_package(
        "designpackage(name=1278.6,path)/lib786_i0m_180h_50pp", params
    )
    assert resolved == "/p/hdk/cad/dp/78p6/v1.0_2/lib786_i0m_180h_50pp"


def test_resolve_design_package_missing_field():
    with pytest.raises(KeyError):
        discover.resolve_design_package("designpackage(name=x,nope)", {})


def test_resolve_lib_root_deref_then_tokens():
    params = {
        "lib_name": "i0m",
        "i0m": "designpackage(name=1278.6,path)/lib786_i0m_180h_50pp",
        "path": "/p/hdk/cad/dp/78p6/designpackage(name=1278.6,version)",
        "version": "v1.0_2",
    }
    assert discover.resolve_lib_root(params) == (
        "/p/hdk/cad/dp/78p6/v1.0_2/lib786_i0m_180h_50pp"
    )


def test_resolve_lib_root_uppercase_key():
    params = {
        "LIB_NAME": "g1i",
        "g1i": "/p/hdk/cad/stdcells/lib764_g1i_210h_50pp/pdk110_r6v2p1_fv",
    }
    assert discover.resolve_lib_root(params) == (
        "/p/hdk/cad/stdcells/lib764_g1i_210h_50pp/pdk110_r6v2p1_fv"
    )


def test_resolve_lib_root_contour_discovery(tmp_path):
    base = tmp_path / "76p5" / "v1.0_2"
    base.mkdir(parents=True)
    for name in [
        "lib765_g1i_210h_50pp_pdk10_r4v0p0_fv",
        "lib765_g1i_210h_50pp_pdk100_anamux",
        "lib765_g1m_240h_50pp_pdk10_r4v0p0_fv",
        "lib765_g1m_240h_100pp_pdk10_r4v0p0_fv",
    ]:
        (base / name).mkdir()

    g1i = discover.resolve_lib_root(
        {"lib_name": "g1i", "lib_height_class": "g1i_7dg_50pp", "path": str(base)}
    )
    assert g1i.endswith("lib765_g1i_210h_50pp_pdk10_r4v0p0_fv")

    g1m = discover.resolve_lib_root(
        {"lib_name": "g1m", "lib_height_class": "g1m_8dg_50pp", "path": str(base)}
    )
    assert g1m.endswith("lib765_g1m_240h_50pp_pdk10_r4v0p0_fv")


def test_resolve_lib_root_contour_missing(tmp_path):
    base = tmp_path / "empty"
    base.mkdir()
    with pytest.raises(FileNotFoundError):
        discover.resolve_lib_root(
            {"lib_name": "g1i", "lib_height_class": "g1i_7dg_50pp", "path": str(base)}
        )


def test_lib_keys_from_lib_name_single():
    assert discover.lib_keys({"lib_name": "i0m", "i0m": "/x"}) == ["i0m"]


def test_lib_keys_compound_split():
    params = {"lib_name": "g1m_g1i", "g1i": "/a", "g1m": "/b"}
    assert discover.lib_keys(params) == ["g1m", "g1i"]


def test_lib_keys_autodetect_no_lib_name():
    params = {
        "name": "1276.4",
        "PDK_DIR": "/p/hdk/cad/pdk/pdk765_r0.9.1",
        "g1i": "/p/hdk/cad/stdcells/lib765_g1i_210h_50pp/pdk091_r0v0p0_fv",
        "g1m": "/p/hdk/cad/stdcells/lib765_g1m_240h_50pp/pdk091_r0v0p0_fv",
        "esd_lib": "/p/hdk/cad/pdk_addon/esd_lib/esd765_r0.9.1",
        "cpipad_lib": "/p/hdk/cad/pdk_addon/cpipad_lib/cpipad765_r0.9.1",
    }
    assert discover.lib_keys(params) == ["g1i", "g1m"]


def test_resolve_lib_roots_compound_direct_paths():
    params = {
        "g1i": "/p/hdk/cad/stdcells/lib765_g1i_210h_50pp/pdk091_r0v0p0_fv",
        "g1m": "/p/hdk/cad/stdcells/lib765_g1m_240h_50pp/pdk091_r0v0p0_fv",
        "esd_lib": "/p/hdk/cad/pdk_addon/esd_lib/esd765_r0.9.1",
    }
    assert discover.resolve_lib_roots(params) == [
        "/p/hdk/cad/stdcells/lib765_g1i_210h_50pp/pdk091_r0v0p0_fv",
        "/p/hdk/cad/stdcells/lib765_g1m_240h_50pp/pdk091_r0v0p0_fv",
    ]


# ---------------------------------------------------------------------------
# ctech SystemVerilog parsing
# ---------------------------------------------------------------------------

def test_parse_ctech_sv(tmp_path, write):
    sv = write(
        tmp_path / "ctech_lib_and.sv",
        "// header comment\n"
        "/* g1ifake000ab1n99x5 hidden (.a(a)); */\n"
        "module ctech_lib_and (\n"
        "   input logic a,\n"
        "   output logic o );\n"
        "   g1iand002ab1n06x5 ctech_lib_and_dcszo (.a(a), .o(o));\n"
        "   wire w;\n"
        "   assign o = a;\n"
        "endmodule\n",
    )
    cell, insts = discover.parse_ctech_sv(sv)
    assert cell == "ctech_lib_and"
    assert insts == ["g1iand002ab1n06x5"]


def test_find_ctech_sv(tmp_path, write):
    write(tmp_path / "ctech_lib_and.sv", "module ctech_lib_and; endmodule\n")
    write(tmp_path / "ctech_lib_buf.sv", "module ctech_lib_buf; endmodule\n")
    write(tmp_path / "CTECH_notes.hdl", "ignore\n")
    write(tmp_path / "other.sv", "module other; endmodule\n")
    found = [os.path.basename(p) for p in discover.find_ctech_sv(str(tmp_path))]
    assert found == ["ctech_lib_and.sv", "ctech_lib_buf.sv"]


# ---------------------------------------------------------------------------
# bmod / bundle enumeration
# ---------------------------------------------------------------------------

def test_parse_bmod_cells(tmp_path, write):
    bmod = write(
        tmp_path / "lib_base_lvt_bmod.v",
        "module g1iaboi22ab1d16x5 (a, y); endmodule\n"
        "module g1iand002ab1n06x5 (a, b, o); endmodule\n",
    )
    assert discover.parse_bmod_cells(bmod) == {
        "g1iaboi22ab1d16x5",
        "g1iand002ab1n06x5",
    }


def test_parse_bmod_cells_gzipped(tmp_path):
    path = tmp_path / "lib_base_lvt_bmod.v.gz"
    with gzip.open(path, "wt") as handle:
        handle.write("module g1iand002ab1n06x5 (a, b, o); endmodule\n")
    assert discover.parse_bmod_cells(str(path)) == {"g1iand002ab1n06x5"}


def test_enumerate_bundles(tmp_path, write):
    lib_root = tmp_path / "lib764_g1i_210h_50pp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    (bundle / "lib").mkdir()
    (bundle / "ndm").mkdir()
    (lib_root / "doc").mkdir()

    write(
        bundle / "verilog" / "lib764_g1i_210h_50pp_base_lvt_bmod.v",
        "module g1iand002ab1n06x5 (a, b, o); endmodule\n",
    )
    write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz", "")
    write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb", "")
    write(bundle / "ndm" / "lib764_g1i_210h_50pp_base_lvt.ndm", "")

    bundles = discover.enumerate_bundles(str(lib_root))
    assert set(bundles) == {"base_lvt"}
    entry = bundles["base_lvt"]
    assert "g1iand002ab1n06x5" in entry["cells"]
    assert entry["lib"] and entry["ldb"] and entry["ndm"]


def test_enumerate_bundles_ldb_wins_over_db(tmp_path, write):
    lib_root = tmp_path / "lib999_myp_pdk"
    bundle = lib_root / "base_lvt"
    (bundle / "verilog").mkdir(parents=True)
    (bundle / "lib").mkdir()
    write(bundle / "verilog" / "x_bmod.v", "module c (a); endmodule\n")
    write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_nldm.ldb", "")
    write(bundle / "lib" / "base_lvt_tttt_0p650v_100c_nldm.db", "")

    ldbs = discover.enumerate_bundles(str(lib_root))["base_lvt"]["ldb"]
    assert [os.path.basename(p) for p in ldbs] == [
        "base_lvt_tttt_0p650v_100c_nldm.ldb"
    ]


# ---------------------------------------------------------------------------
# PVT + nldm selection (spec section 4)
# ---------------------------------------------------------------------------

def test_select_nldm_prefers_target_pvt():
    files = [
        "d/lib_base_lvt_tttt_0p650v_100c_tttt_cmax_ccslnt.lib.gz",
        "d/lib_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
        "d/lib_base_lvt_rcss_0p550v_0c_pcss_cmax_nldm.lib.gz",
    ]
    assert os.path.basename(discover.select_nldm(files)) == (
        "lib_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz"
    )


def test_select_nldm_none_when_no_nldm():
    assert discover.select_nldm(["d/x_ccslnt.lib.gz"]) is None


def test_select_nldm_handles_negative_temp():
    files = [
        "d/lib_tttt_0p650v_m40c_tttt_cmax_nldm.lib.gz",
        "d/lib_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
    ]
    assert "100c" in os.path.basename(discover.select_nldm(files))


def test_select_nldm_ties_break_lexically():
    files = [
        "d/b_tttt_0p650v_100c_tttt_cmin_nldm.lib.gz",
        "d/a_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
    ]
    assert os.path.basename(discover.select_nldm(files)).startswith("a_")


def test_select_nldm_process_corner_is_the_token_before_the_voltage():
    # The trailing 'tttt' is the RC corner; only the token before the voltage
    # identifies the process corner.
    files = [
        "d/lib765_g1i_210h_50pp_base_lvt_tmin_0p650v_100c_tttt_cmin_nldm.lib.gz",
        "d/lib765_g1i_210h_50pp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
    ]
    assert "_tttt_0p650v_" in os.path.basename(discover.select_nldm(files))


def test_select_nldm_dual_voltage_corner():
    files = [
        "d/lib_dsigclk_lvt_tttt_0p650v_0p500v_100c_tttt_cmax_nldm.lib.gz",
        "d/lib_dsigclk_lvt_ssss_0p650v_0p500v_100c_tttt_cmax_nldm.lib.gz",
    ]
    assert "_tttt_0p650v_" in os.path.basename(discover.select_nldm(files))


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
    assert discover.regex_filter(files, compiled) == [
        "d/lib_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.lib.gz"
    ]


def test_regex_filter_union_any():
    files = ["d/a_650v_x.lib.gz", "d/b_850v_x.lib.gz", "d/c_900v_x.lib.gz"]
    compiled = discover.compile_regexes([r"650v", r"850v"])
    assert discover.regex_filter(files, compiled) == [
        "d/a_650v_x.lib.gz",
        "d/b_850v_x.lib.gz",
    ]


def test_regex_filter_empty_patterns():
    assert discover.regex_filter(["a", "b"], []) == []


def test_compile_regexes_invalid():
    with pytest.raises(re.error):
        discover.compile_regexes(["("])
