"""Shared fixtures: synthetic XML dumps and a fake fe_collateral workarea."""

from __future__ import annotations

import gzip
from collections.abc import Sequence
from pathlib import Path

import pytest

BLOCK = "corimh"
DUT = "imh"


def instance_xml(
    module: str,
    library: str,
    rule: str,
    source: str,
    top: bool = False,
) -> str:
    tag = "TopDetails" if top else "InstanceDetails"
    return (
        "<Instance >"
        f"<{tag} >"
        f"<Hierarchy >corimh.{module}_inst</Hierarchy >"
        f"<SourceInfo >{source}</SourceInfo >"
        f"</{tag} >"
        "<DefinitionDetails >"
        f"<Module >{module}</Module >"
        f"<Library >{library}</Library >"
        f"<SourceInfo >{source}</SourceInfo >"
        "</DefinitionDetails >"
        f"<ConfigRule ><Rule >{rule}</Rule ></ConfigRule >"
        "</Instance >"
    )


def make_xml(instances: Sequence[tuple[str, str, str, str]]) -> str:
    """Build a dump body; the first instance is treated as the design top."""
    body = "".join(
        instance_xml(*fields, top=(index == 0)) for index, fields in enumerate(instances)
    )
    return f"<InstanceList >{body}</InstanceList >"


def write_xml(path: Path, instances: Sequence[tuple[str, str, str, str]], gz: bool = False) -> Path:
    text = make_xml(instances)
    if gz:
        path.write_bytes(gzip.compress(text.encode()))
    else:
        path.write_text(text)
    return path


def source_path(source: str) -> str:
    """'"/rtl/a/alpha.sv",10' -> '/rtl/a/alpha.sv'."""
    return source.split('"')[1] if source.startswith('"') else source


def dump_line(module: str, library: str, rule: str, source: str) -> str:
    """The fullchipdump line matching instance_xml() for the same fields."""
    path = source_path(source)
    rule = rule.replace("'", "_")
    return (
        f"{{ 'instance' : r\"corimh.{module}_inst\", 'library' : '{library}', "
        f"'module' : '{module}', 'module_file' : '{path}', "
        f"'config_rule' : '{rule}', 'parent_file' : '{path}' }}"
    )


def make_fullchipdump(instances: Sequence[tuple[str, str, str, str]]) -> str:
    return "".join(dump_line(*fields) + "\n" for fields in instances)


def make_cfg_sv(instances: Sequence[tuple[str, str, str, str]]) -> str:
    """<block>_cfg.sv has no entry for the top; libraries are lower case there."""
    body = "".join(
        f"instance corimh.{module}_inst liblist {library.lower()};\n"
        for module, library, _, _ in instances[1:]
    )
    return f"config gold_config ;\n\ndesign imh.{BLOCK} ;\ndefault liblist work ;\n{body}endconfig\n"


@pytest.fixture
def sample_instances() -> list[tuple[str, str, str, str]]:
    return [
        ("corimh", "IMH", "Top Module", '"/rtl/corimh.sv",1'),
        ("alpha", "LIB_A", "parent cell's library", '"/rtl/a/alpha.sv",10'),
        ("alpha", "LIB_A", "parent cell's library", '"/rtl/a/alpha.sv",10'),
        ("alpha", "LIB_B", "default library search order", '"/rtl/b/alpha.sv",20'),
        ("beta", "LIB_A", "parent cell's library", '"/rtl/a/beta.sv",5'),
    ]


@pytest.fixture
def workarea(tmp_path: Path) -> Path:
    """Build <REF_MODEL>/output/<DUT>/partition/<BLOCK>/h2b/trial/... and return fe_collateral."""
    trial = tmp_path / "model" / "output" / DUT / "partition" / BLOCK / "h2b" / "trial"
    fe_collateral = trial / "fe_collateral"
    fe_collateral.mkdir(parents=True)
    (fe_collateral / f"{BLOCK}_cfg.sv").write_text("config gold_config ;\n")
    (fe_collateral / "rtl_list_2stage.tcl").write_text("# filelist\n")

    fev_v2k = trial / "fev_v2k"
    fev_v2k.mkdir()
    fullchipdump = fev_v2k / "fullchipdump.final.py.sort.zst"
    fullchipdump.write_bytes(b"")

    log_dir = trial / "log"
    log_dir.mkdir()
    (log_dir / f"{BLOCK}.v2k_config.syn.log").write_text(
        "[00:00:00 2026-08-21] [INFO ] starting\n"
        f"[00:00:01 2026-08-21] [INFO ] {fullchipdump} exists! Not re-creating the file\n"
    )

    flow_inputs = trial / "flow_inputs"
    flow_inputs.mkdir()
    xml_path = trial / "config_diagnostics.xml.gz"
    xml_path.write_bytes(gzip.compress(make_xml([("corimh", "IMH", "Top Module", '"/rtl/corimh.sv",1')]).encode()))
    (flow_inputs / "fullchipdump.config.log").write_text(
        "| FULL_CHIP_V2K       | false     | Default  |\n"
        f"| VCS_CONFIG_XML      | {xml_path}     | User-cfg |\n"
    )
    return fe_collateral
