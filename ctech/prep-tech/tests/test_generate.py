"""prep_tech.generate: plan building, rendering, and writing (spec section 3)."""

from prep_tech import config, generate

from conftest import die_dict, make_ctech, make_lib, write_text


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
    assert config == cfg


def test_unreferenced_bundle_is_not_selected(tmp_path):
    lib_root = tmp_path / "lib999_myp_pdk"
    corners = ["x_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz"]
    make_lib(lib_root, "base_lvt", "mypand000ab1n02x5", corners=corners)
    make_lib(lib_root, "base_hvt", "mypnand00ab1n02x5", corners=corners)
    cfg = write_text(
        tmp_path / "a.cth", f"[DESIGNPACKAGE]\nlib_name = myp\nmyp = {lib_root}\n"
    )
    ctech = make_ctech(tmp_path / "ctech", "ctech_lib_x", ["mypand000ab1n02x5"])

    plan = generate.build_die_plan("d", die_dict([cfg], [ctech]))
    assert plan["referenced_keys"] == {"base_lvt"}
    files = generate.render_die_files(plan)
    assert "base_hvt" not in files["stdcell.lib.list.ctech.all"]
    assert "base_hvt" in files["stdcell.lib.list.all"]


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

    assert "_nldm.lib.gz" in files["stdcell.lib.list.ctech"]
    assert "ccslnt" not in files["stdcell.lib.list.ctech"]
    assert "_nldm.lib.gz" in files["stdcell.lib.list.ctech.all"]
    assert "ccslnt" not in files["stdcell.lib.list.ctech.all"]
    assert "_nldm.lib.gz" in files["stdcell.lib.list.all"]
    assert "ccslnt" not in files["stdcell.lib.list.all"]
    assert "base_lvt.ndm" in files["stdcell.ndm.list.ctech"]
    assert "base_lvt.ndm" in files["stdcell.ndm.list.all"]
    for name in ("stdcell.ndm.list.ctech", "stdcell.ndm.list.all"):
        entries = files[name].split()
        assert entries and all(entry.endswith(".ndm") for entry in entries), name
    assert files["stdcell.ldb.list.ctech"].strip().endswith("_nldm.ldb")


def test_render_die_files_is_deterministic(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    assert generate.render_die_files(plan) == generate.render_die_files(plan)


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
    assert "ctech cells found: 1" in report
    assert "referenced stdcells (deduplicated): 1" in report
    assert "unresolved stdcell instantiations: 0" in report


def test_render_csv_columns(fake_project):
    parsed, cfg, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    lines = generate.render_csv([("corimh", plan)]).splitlines()

    assert lines[0] == (
        "die,ctech_cell,stdcell name,stdcell library,"
        "path to configuration file,path to stdcell verilog,"
        "path to ctech verilog"
    )
    assert lines[1].startswith(f"corimh,ctech_lib_x,mycell000ab1n02x5,base_lvt,{cfg},")
    assert lines[1].endswith("ctech_lib_x.sv")


def test_unresolved_stdcell_reported(tmp_path):
    lib_root = tmp_path / "lib999_myp_pdk"
    make_lib(lib_root, "base_lvt", "mypand000ab1n02x5")
    cfg = write_text(
        tmp_path / "a.cth", f"[DESIGNPACKAGE]\nlib_name = myp\nmyp = {lib_root}\n"
    )
    ctech = make_ctech(
        tmp_path / "ctech",
        "ctech_lib_y",
        ["mypand000ab1n02x5", "mypmissing0ab1n02x5", "some_submodule"],
    )

    plan = generate.build_die_plan("corcbbp", die_dict([cfg], [ctech]))

    assert len(plan["unresolved"]) == 1
    ctech_cell, stdcell, sv = plan["unresolved"][0]
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
    assert (out_root / "corimh" / "stdcell.ndm.list.ctech").is_file()
    assert (out_root / "corimh" / "stdcell.ndm.list.all").is_file()
    assert (out_root / "prep_tech.report").is_file()
    assert (out_root / "prep_tech.csv").is_file()
    assert (out_root / "prep_tech.duplicates.csv").is_file()
    assert has_dupes is False
    # 9 die files + report + duplicates.csv + csv.
    assert len(written) == 12
    assert len(plans) == 1


def test_generate_all_is_idempotent(fake_project, tmp_path):
    parsed, _, _ = fake_project
    out_root = tmp_path / "out"
    generate.generate_all(parsed, str(out_root))
    first = (out_root / "corimh" / "stdcell.lib.list.all").read_text()
    generate.generate_all(parsed, str(out_root))
    assert (out_root / "corimh" / "stdcell.lib.list.all").read_text() == first


def test_generate_all_empty_dies(tmp_path):
    out = tmp_path / "explicit_root"
    written, plans, has_dupes = generate.generate_all({"dies": {}}, str(out))
    assert (out / "prep_tech.report").is_file()
    assert (out / "prep_tech.csv").is_file()
    assert (out / "prep_tech.duplicates.csv").is_file()
    assert plans == []
    assert has_dupes is False
    assert len(written) == 3


def test_planned_outputs_matches_generate_all(fake_project, tmp_path):
    parsed, _, _ = fake_project
    out = tmp_path / "out"
    planned = generate.planned_outputs(generate.plan_all(parsed), str(out))
    written, _, _ = generate.generate_all(parsed, str(out))
    assert sorted(planned) == sorted(written)


# ---------------------------------------------------------------------------
# Report structure (spec 3.3)
# ---------------------------------------------------------------------------

def test_report_labels_ip_sections_as_ip(fake_project):
    parsed, _, _ = fake_project
    info = parsed["dies"]["corimh"]
    die_plan = generate.build_die_plan("corimh", dict(info, kind="die"))
    ip_plan = generate.build_die_plan("sbe_ip", dict(info, kind="ip"))
    report = generate.render_report([("corimh", die_plan), ("sbe_ip", ip_plan)])
    assert "die: corimh" in report
    assert "ip: sbe_ip" in report
    assert "die: sbe_ip" not in report


def test_report_defaults_to_die_when_kind_is_absent(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    assert "die: corimh" in generate.render_report([("corimh", plan)])


def test_report_output_key_precedes_the_breakdowns(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    report = generate.render_report([("corimh", plan)])

    assert report.index("# summary") < report.index("# output file key")
    assert report.index("# output file key") < report.index("die: corimh")
    for name, _, _ in generate.OUTPUT_KEY:
        assert f"#   {name}" in report
    assert "usage: Fusion, RTLA (phy aware)." in report


def test_report_lists_configuration_regex_pairs(regex_project):
    info = regex_project["dies"]["corimh"]
    plan = generate.build_die_plan("corimh", info)
    pattern = plan["regexes"][0]
    assert generate.config_regex_pairs(plan) == [(info["config_files"][0], pattern)]

    report = generate.render_report([("corimh", plan)])
    assert "  configuration/regex pairs:" in report
    assert f'    a.cth  r"{pattern}"' in report


def test_configuration_regex_pairs_name_each_source_line(tmp_path, write):
    cfg = write(tmp_path / "78p6_i0m_opt32.cth", "")
    ctech = tmp_path / "ctech"
    ctech.mkdir()
    md = write(
        tmp_path / "in.md",
        f'## CORCBBP DIE\n{ctech}  REGEX=r"aaa"\n{cfg} REGEX=r"bbb"\n',
    )
    info = config.parse_input(md)["dies"]["corcbbp"]
    assert info["regex_pairs"] == [(str(ctech), "aaa"), (cfg, "bbb")]

    plan = generate.build_die_plan("corcbbp", info)
    report = generate.render_report([("corcbbp", plan)])
    assert '    ctech               r"aaa"' in report
    assert '    78p6_i0m_opt32.cth  r"bbb"' in report


# ---------------------------------------------------------------------------
# REGEX-filtered lists
# ---------------------------------------------------------------------------

def test_regex_list_files_rendered(regex_project):
    plan = generate.build_die_plan("corimh", regex_project["dies"]["corimh"])
    files = generate.render_die_files(plan)

    assert "0p650v" in files["stdcell.lib.list.ctech"]
    rgx = files["stdcell.lib.list.ctech.all.regex"]
    assert "0p850v" in rgx
    assert "0p650v" not in rgx
    assert "ccslnt" not in rgx
    assert files["stdcell.ldb.list.ctech.all.regex"].strip().endswith(
        "0p850v_100c_tttt_cmax_nldm.ldb"
    )


def test_regex_report_counts(regex_project):
    plan = generate.build_die_plan("corimh", regex_project["dies"]["corimh"])
    report = generate.render_report([("corimh", plan)])
    assert "bundles in library roots: 2" in report
    assert "ctech-referenced bundles: 1" in report
    assert "stdcell.lib.list.ctech: 1" in report
    assert "stdcell.lib.list.ctech.all: 2" in report
    assert "stdcell.lib.list.ctech.all.regex: 1" in report
    assert "stdcell.lib.list.all: 4" in report
    assert "stdcell.lib.list.all.regex: 2" in report


def test_all_lists_span_unreferenced_bundles(regex_project):
    plan = generate.build_die_plan("corimh", regex_project["dies"]["corimh"])
    files = generate.render_die_files(plan)

    assert "ulvt" not in files["stdcell.lib.list.ctech.all.regex"]

    wide = files["stdcell.lib.list.all.regex"]
    assert "base_lvt" in wide and "ulvt" in wide
    assert "0p650v" not in wide
    assert "ccslnt" not in wide
    assert "ulvt" in files["stdcell.ldb.list.all.regex"]

    unfiltered = files["stdcell.lib.list.all"]
    assert "ulvt" in unfiltered
    assert "0p650v" in unfiltered
    assert "ccslnt" not in unfiltered


def test_ctech_scoped_outputs_exclude_unreferenced_bundles(regex_project):
    plan = generate.build_die_plan("corimh", regex_project["dies"]["corimh"])
    files = generate.render_die_files(plan)
    for name in (
        "static_stdcells.f",
        "stdcell.ndm.list.ctech",
        "stdcell.lib.list.ctech",
        "stdcell.ldb.list.ctech",
        "stdcell.lib.list.ctech.all",
        "stdcell.ldb.list.ctech.all",
    ):
        assert "ulvt" not in files[name], name
    assert "ulvt" in files["stdcell.ndm.list.all"]


def test_no_regex_no_regex_files(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    files = generate.render_die_files(plan)
    assert not [name for name in files if name.endswith(".regex")]
    assert "stdcell.lib.list.all" in files

    report = generate.render_report([("corimh", plan)])
    assert "configuration/regex pairs" not in report
    assert not [
        line for line in report.splitlines() if line.startswith("  stdcell.")
        and ".regex" in line
    ]


# ---------------------------------------------------------------------------
# Configuration-file precedence (spec 2.1): first listed configuration wins
# ---------------------------------------------------------------------------

def test_config_precedence_first_wins(tmp_path, dup_project):
    parsed, cfg_a, cfg_b, lib_a, lib_b = dup_project()
    make_ctech(tmp_path / "ctech", "ctech_lib_x", ["dupcell000ab1n02x5"])
    die_info = parsed["dies"]["d"]

    plan = generate.build_die_plan("d", die_info)
    assert len(plan["refs"]) == 1
    _, stdcell, _, vpath, _, config = plan["refs"][0]
    assert stdcell == "dupcell000ab1n02x5"
    assert lib_a in vpath
    assert lib_b not in vpath
    assert config == cfg_a

    die_info["config_files"] = [cfg_b, cfg_a]
    plan2 = generate.build_die_plan("d", die_info)
    assert lib_b in plan2["refs"][0][3]
    assert plan2["refs"][0][5] == cfg_b


# ---------------------------------------------------------------------------
# Duplicate stdcell definitions across configuration files (spec 2.1 / 3.5)
# ---------------------------------------------------------------------------

def test_duplicate_detected_same_bundle(dup_project):
    parsed, cfg_a, cfg_b, _, _ = dup_project()
    plan = generate.build_die_plan("d", parsed["dies"]["d"])
    assert plan["duplicates"] == [
        ("dupcell000ab1n02x5", "base_lvt", f"{cfg_a}:{cfg_b}")
    ]


def test_duplicate_detected_regardless_of_bundle(dup_project):
    parsed, cfg_a, cfg_b, _, _ = dup_project(bundle_a="base_lvt", bundle_b="clk_lvt")
    cell, bundles, configs = generate.build_die_plan(
        "d", parsed["dies"]["d"]
    )["duplicates"][0]
    assert cell == "dupcell000ab1n02x5"
    assert bundles == "base_lvt:clk_lvt"
    assert configs == f"{cfg_a}:{cfg_b}"


def test_duplicates_csv_header_only_when_none(fake_project):
    parsed, _, _ = fake_project
    plan = generate.build_die_plan("corimh", parsed["dies"]["corimh"])
    assert generate.render_duplicates_csv([("corimh", plan)]) == (
        "die,stdcell library,stdcell name,configuration file list\n"
    )


def test_generate_all_fatal_on_duplicates(tmp_path, dup_project):
    parsed, cfg_a, cfg_b, _, _ = dup_project()
    out = tmp_path / "out"
    written, plans, has_dupes = generate.generate_all(
        parsed, str(out), allow_duplicates=False
    )
    assert has_dupes is True
    assert (out / "prep_tech.report").is_file()
    assert (out / "prep_tech.duplicates.csv").is_file()
    assert not (out / "prep_tech.csv").exists()
    assert not (out / "d").exists()
    assert len(written) == 2
    dup = (out / "prep_tech.duplicates.csv").read_text()
    assert f"d,base_lvt,dupcell000ab1n02x5,{cfg_a}:{cfg_b}" in dup


def test_generate_all_allow_duplicates(tmp_path, dup_project):
    parsed, _, _, _, _ = dup_project()
    out = tmp_path / "out"
    _, _, has_dupes = generate.generate_all(parsed, str(out), allow_duplicates=True)
    assert has_dupes is True
    assert (out / "prep_tech.csv").is_file()
    assert (out / "d" / "static_stdcells.f").is_file()
    assert (out / "prep_tech.duplicates.csv").read_text().count("\n") >= 2
