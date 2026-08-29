"""Shared fixtures: hermetic stdcell release trees, configs and ctech sources."""

import pytest


def write_text(path, text):
    path = str(path)
    with open(path, "w") as handle:
        handle.write(text)
    return path


def die_dict(config_files, ctech_dirs, regexes=None):
    """A parsed-input die entry, as :func:`prep_tech.config.parse_input` builds it."""
    return {
        "config_files": [str(p) for p in config_files],
        "ctech_dirs": [str(p) for p in ctech_dirs],
        "regexes": list(regexes or []),
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
    """650mV and 850mV nldm corners plus a die REGEX targeting the 850mV cmax."""
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
