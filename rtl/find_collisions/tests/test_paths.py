from __future__ import annotations

from pathlib import Path

import pytest

from find_collisions.paths import (
    PreflightError,
    find_config_xml,
    find_fullchipdump,
    parse_fe_collateral,
    resolve_inputs,
)


def test_parse_fe_collateral_splits_layout() -> None:
    ref_model, dut, block = parse_fe_collateral(
        Path("/disk/model-a0-26ww34f/output/imh/partition/corimh/h2b/trial/fe_collateral")
    )
    assert ref_model == Path("/disk/model-a0-26ww34f")
    assert dut == "imh"
    assert block == "corimh"


@pytest.mark.parametrize(
    "path",
    [
        "/disk/model/output/imh/partition/corimh/h2b/trial",
        "/disk/model/imh/partition/corimh/h2b/trial/fe_collateral",
        "/disk/model/output/partition/corimh/h2b/trial/fe_collateral",
    ],
)
def test_parse_fe_collateral_rejects_bad_shapes(path: str) -> None:
    with pytest.raises(PreflightError):
        parse_fe_collateral(Path(path))


def test_find_fullchipdump_scrapes_log(tmp_path: Path) -> None:
    log = tmp_path / "corimh.v2k_config.syn.log"
    log.write_text(
        "[INFO ] preamble\n"
        "[INFO ] /disk/x/h2b/trial/fev_v2k/fullchipdump.final.py.sort.zst exists!\n"
    )
    assert find_fullchipdump(log) == Path(
        "/disk/x/h2b/trial/fev_v2k/fullchipdump.final.py.sort.zst"
    )


def test_find_fullchipdump_missing_entry(tmp_path: Path) -> None:
    log = tmp_path / "log"
    log.write_text("nothing here\n")
    with pytest.raises(PreflightError):
        find_fullchipdump(log)


def test_find_config_xml_parses_table(tmp_path: Path) -> None:
    fev = tmp_path / "fev_v2k"
    fev.mkdir()
    flow_inputs = tmp_path / "flow_inputs"
    flow_inputs.mkdir()
    (flow_inputs / "fullchipdump.config.log").write_text(
        "| VCSSIM_COMPILE_DIR   |            | Default  |\n"
        "| VCS_CONFIG_XML       | /disk/x/config_diagnostics.xml.gz   | User-cfg |\n"
    )
    xml, log = find_config_xml(fev / "fullchipdump.final.py.sort.zst")
    assert xml == Path("/disk/x/config_diagnostics.xml.gz")
    assert log == flow_inputs / "fullchipdump.config.log"


def test_resolve_inputs_end_to_end(workarea: Path) -> None:
    inputs = resolve_inputs(workarea)
    assert inputs.block == "corimh"
    assert inputs.dut == "imh"
    assert inputs.cfg_sv.name == "corimh_cfg.sv"
    assert inputs.rtl_list.name == "rtl_list_2stage.tcl"
    assert inputs.fullchipdump.name == "fullchipdump.final.py.sort.zst"
    assert inputs.config_xml.name == "config_diagnostics.xml.gz"


def test_resolve_inputs_missing_cfg_sv(workarea: Path) -> None:
    (workarea / "corimh_cfg.sv").unlink()
    with pytest.raises(PreflightError, match="S1"):
        resolve_inputs(workarea)


def test_resolve_inputs_missing_directory(tmp_path: Path) -> None:
    with pytest.raises(PreflightError):
        resolve_inputs(tmp_path / "nope" / "fe_collateral")
