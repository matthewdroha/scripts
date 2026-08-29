from __future__ import annotations

import gzip
from pathlib import Path

from conftest import make_xml, write_xml

from find_collisions.xmlstream import (
    Definition,
    iter_records,
    open_xml,
    scan_dump,
)


def test_open_xml_plain(tmp_path: Path, sample_instances: list) -> None:
    path = write_xml(tmp_path / "d.xml", sample_instances)
    with open_xml(path) as handle:
        assert handle.read().startswith(b"<InstanceList >")


def test_open_xml_gzipped(tmp_path: Path, sample_instances: list) -> None:
    path = write_xml(tmp_path / "d.xml.gz", sample_instances, gz=True)
    with open_xml(path) as handle:
        assert handle.read().startswith(b"<InstanceList >")


def test_open_xml_detects_gzip_without_suffix(tmp_path: Path) -> None:
    path = tmp_path / "dump.xml"
    path.write_bytes(gzip.compress(make_xml([("m", "L", "r", '"/x.sv",1')]).encode()))
    with open_xml(path) as handle:
        assert b"<Module >m</Module >" in handle.read()


def test_iter_records_yields_tuples_in_order(tmp_path: Path, sample_instances: list) -> None:
    path = write_xml(tmp_path / "d.xml", sample_instances)
    with open_xml(path) as handle:
        records = list(iter_records(handle))
    assert records[0].definition == Definition(
        "corimh", "IMH", "Top Module", '"/rtl/corimh.sv",1'
    )
    assert len(records) == len(sample_instances)


def test_iter_records_captures_details_only_when_wanted(
    tmp_path: Path, sample_instances: list
) -> None:
    path = write_xml(tmp_path / "d.xml", sample_instances)
    with open_xml(path) as handle:
        records = list(iter_records(handle, want_details=lambda module: module == "alpha"))
    wanted = [r for r in records if r.definition.module == "alpha"]
    assert all(r.instance == "corimh.alpha_inst" for r in wanted)
    assert all(r.instance_source for r in wanted)
    assert all(r.instance == "" for r in records if r.definition.module != "alpha")


def test_iter_records_logs_progress(tmp_path: Path, sample_instances: list) -> None:
    path = write_xml(tmp_path / "d.xml", sample_instances)
    messages: list[str] = []
    with open_xml(path) as handle:
        list(iter_records(handle, log=messages.append, progress_every=2))
    assert messages[-1].endswith("(final)")
    assert any("processed 2 instances" == m for m in messages)


def test_scan_dump_aggregates(tmp_path: Path, sample_instances: list) -> None:
    path = write_xml(tmp_path / "d.xml.gz", sample_instances, gz=True)
    scan = scan_dump(path)
    assert (
        scan.counts[Definition("alpha", "LIB_A", "parent cell's library", '"/rtl/a/alpha.sv",10')]
        == 2
    )
    assert sum(scan.counts.values()) == len(sample_instances)
    assert scan.instances == []


def test_scan_dump_collects_wanted_instances(tmp_path: Path, sample_instances: list) -> None:
    path = write_xml(tmp_path / "d.xml.gz", sample_instances, gz=True)
    scan = scan_dump(path, want_details=lambda module: module == "alpha")
    assert len(scan.instances) == 3
    assert {r.definition.module for r in scan.instances} == {"alpha"}
    assert sum(scan.counts.values()) == len(sample_instances)
