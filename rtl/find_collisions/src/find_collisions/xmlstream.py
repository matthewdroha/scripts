"""Streaming reader for the VCS elaboration dump (config_diagnostics.xml[.gz])."""

from __future__ import annotations

import gzip
import xml.etree.ElementTree as ET
from collections import Counter
from collections.abc import Callable, Iterator
from pathlib import Path
from typing import BinaryIO, NamedTuple

GZIP_MAGIC = b"\x1f\x8b"
PROGRESS_EVERY = 1_000_000


class Definition(NamedTuple):
    module: str
    library: str
    configrule: str
    source: str


class InstanceRecord(NamedTuple):
    definition: Definition
    instance: str
    instance_source: str


class Scan(NamedTuple):
    counts: Counter[Definition]
    instances: list[InstanceRecord]


def open_xml(path: Path) -> BinaryIO:
    """Open the dump, transparently decompressing it when gzipped (by magic byte)."""
    handle = open(path, "rb")
    magic = handle.read(2)
    handle.seek(0)
    if magic == GZIP_MAGIC:
        return gzip.open(handle, "rb")  # type: ignore[return-value]
    return handle


def _text(element: ET.Element, path: str) -> str:
    found = element.find(path)
    if found is None or found.text is None:
        return ""
    # Not stripped: an escaped Verilog identifier is terminated by a space, so
    # "corimh.\lcb_x[0] " and "corimh.\lcb_x[0]" are different instances.
    return found.text


def _instance_details(element: ET.Element) -> tuple[str, str]:
    details = element.find("InstanceDetails")
    if details is None:
        details = element.find("TopDetails")
    if details is None:
        return "", ""
    return _text(details, "Hierarchy"), _text(details, "SourceInfo")


def iter_records(
    handle: BinaryIO,
    log: Callable[[str], None] | None = None,
    progress_every: int = PROGRESS_EVERY,
    want_details: Callable[[str], bool] | None = None,
) -> Iterator[InstanceRecord]:
    """Yield one record per <Instance>, keeping memory bounded on 14 GB+ dumps."""
    context = ET.iterparse(handle, events=("start", "end"))
    _, root = next(context)
    count = 0
    for event, element in context:
        if event != "end" or element.tag != "Instance":
            continue
        count += 1
        definition = Definition(
            module=_text(element, "DefinitionDetails/Module"),
            library=_text(element, "DefinitionDetails/Library"),
            configrule=_text(element, "ConfigRule/Rule"),
            source=_text(element, "DefinitionDetails/SourceInfo"),
        )
        if want_details is not None and want_details(definition.module):
            instance, instance_source = _instance_details(element)
        else:
            instance, instance_source = "", ""
        yield InstanceRecord(definition, instance, instance_source)
        root.clear()
        if log and progress_every and count % progress_every == 0:
            log(f"processed {count:,} instances")
    if log:
        log(f"processed {count:,} instances (final)")


def scan_dump(
    path: Path,
    log: Callable[[str], None] | None = None,
    progress_every: int = PROGRESS_EVERY,
    want_details: Callable[[str], bool] | None = None,
    observe: Callable[[InstanceRecord], None] | None = None,
) -> Scan:
    """Single pass: instance counts per definition, plus records for wanted modules.

    ``observe`` (used by --paranoia) sees every record and forces instance
    details on for all of them, but nothing extra is retained.
    """
    counts: Counter[Definition] = Counter()
    instances: list[InstanceRecord] = []
    details = (lambda module: True) if observe is not None else want_details
    with open_xml(path) as handle:
        records = iter_records(
            handle, log=log, progress_every=progress_every, want_details=details
        )
        for record in records:
            counts[record.definition] += 1
            if observe is not None:
                observe(record)
            if want_details is not None and want_details(record.definition.module):
                instances.append(record)
    return Scan(counts=counts, instances=instances)
