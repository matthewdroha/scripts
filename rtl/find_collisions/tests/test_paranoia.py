from __future__ import annotations

import gzip
from pathlib import Path

import pytest
import zstandard
from conftest import dump_line, make_cfg_sv, make_fullchipdump, write_xml

from find_collisions.paranoia import (
    CFG_RE,
    DUMP_RE,
    EXAMPLE_LIMIT,
    HashIndex,
    ParanoiaChecker,
    build_checker,
    open_text,
    paranoia_lines,
    source_path,
)
from find_collisions.xmlstream import scan_dump

PARENT = "parent cell's library"
SEARCH = "default library search order"

INSTANCES = [
    ("corimh", "IMH", "Top Module", '"/rtl/corimh.sv",1'),
    ("alpha", "LIB_A", PARENT, '"/rtl/a/alpha.sv",10'),
    ("beta", "LIB_B", SEARCH, '"/rtl/b/beta.sv",20'),
]

# an escaped Verilog identifier keeps the space that terminates it
ESCAPED = r"corimh.top.\lcb_Clk[g_bank][g_entry] .i_ctech_lib_clk_and_en"


def write_inputs(tmp_path: Path, dump_text: str, cfg_text: str) -> tuple[Path, Path]:
    dump = tmp_path / "fullchipdump.final.py.sort"
    dump.write_text(dump_text)
    cfg = tmp_path / "corimh_cfg.sv"
    cfg.write_text(cfg_text)
    return dump, cfg


def check(tmp_path: Path, xml_instances, dump_text: str, cfg_text: str):
    dump, cfg = write_inputs(tmp_path, dump_text, cfg_text)
    checker = build_checker(dump, cfg)
    scan_dump(write_xml(tmp_path / "dump.xml", xml_instances), observe=checker)
    return checker.result()


def test_open_text_handles_plain_gzip_and_zstd(tmp_path: Path) -> None:
    plain = tmp_path / "plain.txt"
    plain.write_text("one\ntwo\n")
    gz = tmp_path / "packed.gz"
    gz.write_bytes(gzip.compress(b"one\ntwo\n"))
    zst = tmp_path / "packed.zst"
    zst.write_bytes(zstandard.ZstdCompressor().compress(b"one\ntwo\n"))
    for path in (plain, gz, zst):
        with open_text(path) as handle:
            assert handle.read() == "one\ntwo\n"


def test_dump_re_parses_escaped_identifier() -> None:
    line = (
        f"{{ 'instance' : r\"{ESCAPED}\", 'library' : 'SCA_LIB', "
        "'module' : 'sca_lcb', 'module_file' : '/rtl/sca_lcb.sv', "
        "'config_rule' : 'parent cell_s library', 'parent_file' : '/rtl/top.sv' }"
    )
    match = DUMP_RE.search(line)
    assert match is not None
    assert match["instance"] == ESCAPED
    assert match["library"] == "SCA_LIB"
    assert match["config_rule"] == "parent cell_s library"
    assert match["parent_file"] == "/rtl/top.sv"


def test_cfg_re_keeps_trailing_space_of_escaped_identifier() -> None:
    trailing = r"corimh.top.\lcb_Clk[g_bank][g_entry] "
    match = CFG_RE.match(f"instance {trailing} liblist sca_lib;\n")
    assert match is not None
    assert match["instance"] == trailing
    assert match["library"] == "sca_lib"


def test_cfg_re_ignores_non_instance_lines() -> None:
    for line in ("config gold_config ;\n", "\n", "design imh.corimh ;\n", "endconfig\n"):
        assert CFG_RE.match(line) is None


def test_source_path_strips_line_number() -> None:
    assert source_path('"/rtl/a/alpha.sv",10') == "/rtl/a/alpha.sv"
    assert source_path("/rtl/a/alpha.sv") == "/rtl/a/alpha.sv"


def test_hash_index_membership() -> None:
    index = HashIndex([5, -3, 9])
    assert index.total == 3
    assert -3 in index and 9 in index
    assert 4 not in index


def test_consistent_inputs_report_no_differences(tmp_path: Path) -> None:
    result = check(tmp_path, INSTANCES, make_fullchipdump(INSTANCES), make_cfg_sv(INSTANCES))
    assert result.xml_instances == 3
    assert result.dump_instances == 3
    assert result.differences == 0
    assert result.cfg_instances == 2
    assert result.cfg_mismatched == 0


def test_instance_missing_from_dump_is_reported(tmp_path: Path) -> None:
    result = check(tmp_path, INSTANCES, make_fullchipdump(INSTANCES[:2]), make_cfg_sv(INSTANCES))
    assert result.xml_only == 1
    assert result.dump_only == 0
    assert result.xml_missing_examples == [dump_line(*INSTANCES[2])]
    assert result.dump_missing_examples == []


def test_changed_binding_counts_on_both_sides(tmp_path: Path) -> None:
    rebound = [*INSTANCES[:2], ("beta", "LIB_C", SEARCH, '"/rtl/c/beta.sv",20')]
    result = check(tmp_path, INSTANCES, make_fullchipdump(rebound), make_cfg_sv(INSTANCES))
    assert (result.xml_only, result.dump_only) == (1, 1)
    assert result.xml_missing_examples == [dump_line(*INSTANCES[2])]
    assert result.dump_missing_examples == [dump_line(*rebound[2])]


def test_duplicate_xml_records_are_reported_not_double_counted(tmp_path: Path) -> None:
    duplicated = [*INSTANCES, INSTANCES[2]]
    result = check(tmp_path, duplicated, make_fullchipdump(INSTANCES), make_cfg_sv(INSTANCES))
    assert result.xml_instances == 4
    assert result.dump_instances == 3
    assert result.differences == 0
    assert result.xml_duplicates == 1
    assert result.duplicate_examples == [dump_line(*INSTANCES[2])]
    assert result.cfg_mismatched == 0
    text = "\n".join(paranoia_lines(result))
    assert "  duplicate xml records: 1" in text


def test_extra_dump_instance_is_reported(tmp_path: Path) -> None:
    extra = dump_line("gamma", "LIB_A", PARENT, '"/rtl/a/gamma.sv",3')
    result = check(
        tmp_path, INSTANCES, make_fullchipdump(INSTANCES) + extra + "\n", make_cfg_sv(INSTANCES)
    )
    assert (result.xml_only, result.dump_only) == (0, 1)
    assert result.xml_missing_examples == []
    assert result.dump_missing_examples == [extra]


def test_cfg_library_mismatch_is_counted_and_named(tmp_path: Path) -> None:
    cfg = make_cfg_sv(INSTANCES).replace("liblist lib_b;", "liblist lib_z;")
    result = check(tmp_path, INSTANCES, make_fullchipdump(INSTANCES), cfg)
    assert result.cfg_instances == 2
    assert result.cfg_mismatched == 1
    assert result.cfg_mismatch_examples == ["instance corimh.beta_inst liblist lib_z;"]


def test_cfg_library_case_is_ignored(tmp_path: Path) -> None:
    cfg = make_cfg_sv(INSTANCES).replace("liblist lib_b;", "liblist LIB_B;")
    result = check(tmp_path, INSTANCES, make_fullchipdump(INSTANCES), cfg)
    assert result.cfg_mismatched == 0


def test_examples_are_capped(tmp_path: Path) -> None:
    many = [INSTANCES[0]] + [
        (f"mod{index}", "LIB_A", PARENT, f'"/rtl/mod{index}.sv",1') for index in range(30)
    ]
    dump, cfg = write_inputs(tmp_path, "", make_cfg_sv(many))
    checker = ParanoiaChecker(HashIndex([]), HashIndex([]), cfg_sv=cfg)
    scan_dump(write_xml(tmp_path / "dump.xml", many), observe=checker)
    result = checker.result()
    assert result.xml_only == 31
    assert len(result.xml_missing_examples) == EXAMPLE_LIMIT


def test_paranoia_lines_render_clean_and_dirty_runs(tmp_path: Path) -> None:
    clean = check(tmp_path, INSTANCES, make_fullchipdump(INSTANCES), make_cfg_sv(INSTANCES))
    lines = paranoia_lines(clean)
    assert lines[0] == "paranoia results:"
    assert "  xml instance count:          3" in lines
    assert "  fullchipdump instance count: 3" in lines
    assert "  differences found: none" in lines
    assert "  v2k config (corimh_cfg.sv) compare" in lines
    assert "    instances in corimh_cfg.sv: 2" in lines
    assert "    v2k config binding mismatch from xml: 0" in lines

    dirty = check(tmp_path, INSTANCES, make_fullchipdump(INSTANCES[:2]), make_cfg_sv(INSTANCES))
    text = "\n".join(paranoia_lines(dirty))
    assert "differences found: 1" in text
    assert "    xml instances missing from the fullchipdump: 1" in text
    assert f"      {dump_line(*INSTANCES[2])}" in text


def test_scan_dump_keeps_observer_records_out_of_memory(tmp_path: Path) -> None:
    seen: list[str] = []
    scan = scan_dump(
        write_xml(tmp_path / "dump.xml", INSTANCES),
        observe=lambda record: seen.append(record.instance),
    )
    assert seen == ["corimh.corimh_inst", "corimh.alpha_inst", "corimh.beta_inst"]
    assert scan.instances == []


@pytest.mark.parametrize("compress", [False, True])
def test_build_checker_reads_compressed_dump(tmp_path: Path, compress: bool) -> None:
    text = make_fullchipdump(INSTANCES)
    dump = tmp_path / "fullchipdump.final.py.sort.zst"
    dump.write_bytes(
        zstandard.ZstdCompressor().compress(text.encode()) if compress else text.encode()
    )
    cfg = tmp_path / "corimh_cfg.sv"
    cfg.write_text(make_cfg_sv(INSTANCES))
    assert build_checker(dump, cfg).result().dump_instances == 3
