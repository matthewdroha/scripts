"""Shared fixtures: hermetic stdcell release trees, configs and ctech sources."""

import pytest


def write_text(path, text):
    path = str(path)
    with open(path, "w") as handle:
        handle.write(text)
    return path


def die_dict(config_files, ctech_dirs, regexes=None):
    """A parsed-input die entry, as :func:`prep_tech.config.parse_input` builds it.

    Each regex is attached to the last configuration file, as an input file
    carrying ``<config> REGEX=r"..."`` on one line would produce.
    """
    configs = [str(p) for p in config_files]
    regexes = list(regexes or [])
    return {
        "config_files": configs,
        "ctech_dirs": [str(p) for p in ctech_dirs],
        "regexes": regexes,
        "regex_pairs": [(configs[-1], rgx) for rgx in regexes] if configs else [],
        "missing": [],
    }


def make_lib(root, bundle_name, cell, corners=()):
    """Build a bundle under *root* with a bmod plus optional lib/ldb/ndm corners."""
    bundle = root / bundle_name
    (bundle / "verilog").mkdir(parents=True)
    write_text(
        bundle / "verilog" / f"lib999_{bundle_name}_bmod.v",
        f"module {cell} (a, o); endmodule\n",
    )
    if corners:
        (bundle / "lib").mkdir()
        (bundle / "ndm").mkdir()
        for name in corners:
            write_text(bundle / "lib" / name, "")
        write_text(bundle / "ndm" / f"lib999_{bundle_name}.ndm", "")
        # Real ndm/ directories ship label and rule sidecars next to the .ndm.
        write_text(bundle / "ndm" / f"lib999_{bundle_name}_labels.tcl", "")
        write_text(bundle / "ndm" / f"lib999_{bundle_name}_rules.tcl", "")
    return bundle


def make_ctech(directory, cell, instances):
    directory.mkdir(exist_ok=True)
    body = "".join(f"   {inst} u{i} (.a(a), .o(o));\n" for i, inst in enumerate(instances))
    write_text(
        directory / f"{cell}.sv",
        f"module {cell} (input a, output o);\n{body}endmodule\n",
    )
    return directory


def make_config(path, lib_name, lib_root):
    return write_text(path, f"[DESIGNPACKAGE]\nlib_name = {lib_name}\n{lib_name} = {lib_root}\n")


TSMC_CORNERS = [
    "ffgnp_0p825v_125c_cbest_CCbest_T_hm_lvf",
    "ssgnp_0p675v_125c_cworst_CCworst_T_hm_lvf",
    "tt_0p65v_85c_typical_hm_lvf",
    "tt_0p75v_85c_typical_hm_lvf",
]


def make_foundry_release(root, libs):
    """A TSMC-style release: one ``<lib>_lib`` dir per entry plus a designpackage.tcl.

    *libs* maps library name -> stdcell module name. Timing is CCS/LVF only, as
    in N2P/N3P. Returns the designpackage.tcl path (relative to *root*).
    """
    rel_tcl = "flowinterface/stack/h156p48/designpackage.tcl"
    lines = [
        'set ivar(techlib_dir) "/elsewhere/not/vanity"',
        f'set ivar(link_libs)  "{" ".join(libs)} n02p_dtcd_lib"',
    ]
    for lib, cell in libs.items():
        base = root / lib
        (base / "verilog" / "v110a").mkdir(parents=True)
        write_text(base / "verilog" / "v110a" / f"{lib}.v", f"module {cell} (A, Z); endmodule\n")
        prefix = f"$ivar(techlib_dir)/{lib}"
        lines.append(
            f'set ivar(lib,{lib},verilog_default_filelist) "{prefix}/verilog/v110a/{lib}.v"'
        )
        lines.append(f'set ivar(lib,{lib},ndm_reflist) "{prefix}/ndm_3.0/v110b/{lib}.ndm"')
        lines.append(f'set ivar(lib,{lib},lib_nldm_filelist,T_85) ""')
        for corner in TSMC_CORNERS:
            key = corner.split("_", 1)[0][0].upper()
            for ext, kind in ((".lib.gz", "lib"), (".db", "db")):
                path = f"{prefix}/LVF/CCS/v110b/{lib.removesuffix('_lib')}{corner}{ext}"
                lines.append(f'set ivar(lib,{lib},{kind}_ccs_filelist,{key}) "{path}"')
                lines.append(f'set ivar(lib,{lib},fusion_{kind}_ccs_filelist,{key}) "{path}"')
    (root / "flowinterface" / "stack" / "h156p48").mkdir(parents=True)
    write_text(root / rel_tcl, "\n".join(lines) + "\n")
    return rel_tcl


def make_foundry_config(directory, release_root, rel_tcl):
    """Top-level config that reaches ``path``/``dpvarspath`` via INCLUDES and ``$DP_PATH``."""
    inc = write_text(
        directory / "dp_generic.cth",
        "[DESIGNPACKAGE]\n"
        "lib_height_class = h156p48\n"
        "name = n2p\n"
        "path = $DP_PATH\n"
        f"dpvarspath = {rel_tcl}\n"
        "[ENVS]\n"
        "DP_PATH = $RELEASE_BASE/$DP_VERSION\n"
        f"RELEASE_BASE = {release_root.parent}\n"
        f"DP_VERSION = {release_root.name}\n",
    )
    return write_text(
        directory / "n2p_htall_conf7.cth", f"[INCLUDES]\n{inc}\n[DESIGNPACKAGE]\nname = n2p\n"
    )


@pytest.fixture
def foundry_project(tmp_path):
    """TSMC-style die: config chain -> designpackage.tcl -> two CCS-only bundles.

    Returns ``(parsed, config_path, release_root)``.
    """
    release = tmp_path / "tech-release" / "v1.1.5"
    rel_tcl = make_foundry_release(
        release,
        {
            "tcbn02p_bwph156pnpnl3p48cpd_base_lvt_c240429_lib": "AN2D2BWP156HPNPN3P48CPDLVT",
            "tcbn02p_bwph156pnpnl3p48cpd_base_ulvt_c240429_lib": "AN2D2BWP156HPNPN3P48CPDULVT",
        },
    )
    cfg = make_foundry_config(tmp_path, release, rel_tcl)
    ctech = make_ctech(
        tmp_path / "ctech",
        "ctech_lib_and",
        ["AN2D2BWP156HPNPN3P48CPDLVT", "MISSINGBWP156HPNPN3P48CPDLVT", "ctech_lib_sub"],
    )
    parsed = {"dies": {"hovis": die_dict([cfg], [ctech])}}
    return parsed, cfg, str(release)


@pytest.fixture
def write():
    return write_text


@pytest.fixture
def die():
    return die_dict


@pytest.fixture
def fake_project(tmp_path):
    """One config, one bundle with full collateral, one ctech cell that uses it.

    Returns ``(parsed, config_path, lib_root)``.
    """
    lib_root = tmp_path / "lib999_myp_180h_50pp_pdk"
    make_lib(
        lib_root,
        "base_lvt",
        "mycell000ab1n02x5",
        corners=[
            "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
            "base_lvt_tttt_0p650v_100c_tttt_cmax_ccslnt.lib.gz",
            "base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb",
        ],
    )
    cfg = make_config(tmp_path / "a.cth", "myp", lib_root)
    ctech = make_ctech(tmp_path / "ctech", "ctech_lib_x", ["mycell000ab1n02x5"])
    parsed = {"dies": {"corimh": die_dict([cfg], [ctech])}}
    return parsed, cfg, str(lib_root)


@pytest.fixture
def regex_project(tmp_path):
    """650mV and 850mV nldm corners plus a die REGEX targeting the 850mV cmax.

    ``ulvt`` is deliberately never instantiated by ctech, so it appears only in
    the library-wide ``*.list.all.regex`` outputs.
    """
    lib_root = tmp_path / "lib999_myp_pdk"
    make_lib(
        lib_root,
        "base_lvt",
        "mypand000ab1n02x5",
        corners=[
            "myp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
            "myp_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.lib.gz",
            "myp_base_lvt_tttt_0p850v_100c_tttt_cmax_ccslnt.lib.gz",
            "myp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.ldb",
            "myp_base_lvt_tttt_0p850v_100c_tttt_cmax_nldm.ldb",
        ],
    )
    make_lib(
        lib_root,
        "ulvt",
        "mypnor000ab1n02x5",
        corners=[
            "myp_ulvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz",
            "myp_ulvt_tttt_0p850v_100c_tttt_cmax_nldm.lib.gz",
            "myp_ulvt_tttt_0p850v_100c_tttt_cmax_nldm.ldb",
        ],
    )
    cfg = make_config(tmp_path / "a.cth", "myp", lib_root)
    ctech = make_ctech(tmp_path / "ctech", "ctech_lib_x", ["mypand000ab1n02x5"])
    return {
        "dies": {
            "corimh": die_dict(
                [cfg], [ctech], regexes=[r"tttt\S+850v\S+100c\S+cmax"]
            )
        }
    }


@pytest.fixture
def dup_project(tmp_path):
    """Two configs whose libraries both define ``dupcell000ab1n02x5``.

    Returns ``(factory, )`` style callable: ``dup_project(bundle_a, bundle_b)``.
    """

    def build(bundle_a="base_lvt", bundle_b="base_lvt"):
        lib_a = tmp_path / "lib999_a_pdk"
        lib_b = tmp_path / "lib999_b_pdk"
        make_lib(lib_a, bundle_a, "dupcell000ab1n02x5")
        make_lib(lib_b, bundle_b, "dupcell000ab1n02x5")
        cfg_a = make_config(tmp_path / "a.cth", "a", lib_a)
        cfg_b = make_config(tmp_path / "b.cth", "b", lib_b)
        ctech = make_ctech(tmp_path / "ctech", "ctech_lib_x", [])
        parsed = {"dies": {"d": die_dict([cfg_a, cfg_b], [ctech])}}
        return parsed, cfg_a, cfg_b, str(lib_a), str(lib_b)

    return build
