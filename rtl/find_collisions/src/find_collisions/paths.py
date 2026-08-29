"""Discovery of the four handoff input files (S1-S4) from a fe_collateral directory."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path

FULLCHIPDUMP_RE = re.compile(r"(/\S*fullchipdump\.final\.py\.sort(?:\.zst)?)")
VCS_CONFIG_XML_RE = re.compile(r"^\|\s*VCS_CONFIG_XML\s*\|\s*(\S+)\s*\|")


class PreflightError(Exception):
    """An input could not be located, or a path does not have the expected shape."""


@dataclass(frozen=True)
class Inputs:
    """Every resolved input path plus the identifiers derived from the layout."""

    fe_collateral: Path
    ref_model: Path
    dut: str
    block: str
    cfg_sv: Path
    rtl_list: Path
    v2k_log: Path
    fullchipdump: Path
    config_xml: Path


def parse_fe_collateral(fe_collateral: Path) -> tuple[Path, str, str]:
    """Split <REF_MODEL>/output/<DUT>/partition/<BLOCK>/h2b/trial/fe_collateral."""
    path = Path(os.path.abspath(fe_collateral))
    parts = path.parts
    if not parts or parts[-1] != "fe_collateral":
        raise PreflightError(f"not a fe_collateral directory: {path}")
    try:
        partition_idx = len(parts) - 1 - parts[::-1].index("partition")
        output_idx = len(parts) - 1 - parts[::-1].index("output", len(parts) - partition_idx)
    except ValueError as exc:
        raise PreflightError(
            f"cannot derive DUT/BLOCK from {path}: expected "
            "<REF_MODEL>/output/<DUT>/partition/<BLOCK>/h2b/trial/fe_collateral"
        ) from exc
    if partition_idx + 1 >= len(parts) or output_idx + 1 >= partition_idx:
        raise PreflightError(f"cannot derive DUT/BLOCK from {path}")
    return Path(*parts[:output_idx]), parts[output_idx + 1], parts[partition_idx + 1]


def find_fullchipdump(v2k_log: Path) -> Path:
    """Scrape the fullchipdump path out of <BLOCK>.v2k_config.syn.log (S3)."""
    with open(v2k_log, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            match = FULLCHIPDUMP_RE.search(line)
            if match:
                return Path(match.group(1))
    raise PreflightError(f"no fullchipdump.final.py.sort path found in {v2k_log}")


def find_config_xml(fullchipdump: Path) -> tuple[Path, Path]:
    """Read VCS_CONFIG_XML out of the sibling flow_inputs config log (S4)."""
    config_log = fullchipdump.parent.parent / "flow_inputs" / "fullchipdump.config.log"
    if not config_log.is_file():
        raise PreflightError(f"missing fullchipdump config log: {config_log}")
    with open(config_log, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            match = VCS_CONFIG_XML_RE.match(line)
            if match:
                return Path(match.group(1)), config_log
    raise PreflightError(f"no VCS_CONFIG_XML entry found in {config_log}")


def resolve_inputs(fe_collateral: Path) -> Inputs:
    """Locate and validate S1-S4. Raises PreflightError on the first problem."""
    fe_collateral = Path(os.path.abspath(fe_collateral))
    if not fe_collateral.is_dir():
        raise PreflightError(f"missing fe_collateral directory: {fe_collateral}")
    ref_model, dut, block = parse_fe_collateral(fe_collateral)

    cfg_sv = fe_collateral / f"{block}_cfg.sv"
    if not cfg_sv.is_file():
        raise PreflightError(f"missing generated config (S1): {cfg_sv}")

    rtl_list = fe_collateral / "rtl_list_2stage.tcl"
    if not rtl_list.is_file():
        raise PreflightError(f"missing handoff filelist (S2): {rtl_list}")

    v2k_log = fe_collateral.parent / "log" / f"{block}.v2k_config.syn.log"
    if not v2k_log.is_file():
        raise PreflightError(f"missing v2k config log: {v2k_log}")

    fullchipdump = find_fullchipdump(v2k_log)
    if not fullchipdump.is_file():
        raise PreflightError(f"missing fullchipdump (S3): {fullchipdump}")

    config_xml, _ = find_config_xml(fullchipdump)
    if not config_xml.is_file():
        raise PreflightError(f"missing config diagnostics XML (S4): {config_xml}")

    return Inputs(
        fe_collateral=fe_collateral,
        ref_model=ref_model,
        dut=dut,
        block=block,
        cfg_sv=cfg_sv,
        rtl_list=rtl_list,
        v2k_log=v2k_log,
        fullchipdump=fullchipdump,
        config_xml=config_xml,
    )
