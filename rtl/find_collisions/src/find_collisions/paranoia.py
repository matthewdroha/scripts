"""--paranoia: cross-check the XML dump against the fullchipdump and the _cfg.sv.

Two independent checks, both driven off the single streaming pass over the XML:

1. every XML instance also appears -- with the same binding -- in the fullchipdump
2. every binding in <block>_cfg.sv is the binding the elaborator actually used

Both reference files are far too large to hold as parsed records (24M and 16M
lines), so each is reduced to a sorted array of 64 bit hashes (~8 bytes/record
instead of ~80 for a set of ints) that the XML pass probes.
"""

from __future__ import annotations

import gzip
import io
import re
from array import array
from bisect import bisect_left
from collections.abc import Callable, Iterable, Iterator
from dataclasses import dataclass, field
from pathlib import Path
from typing import IO

from find_collisions.xmlstream import InstanceRecord

GZIP_MAGIC = b"\x1f\x8b"
ZSTD_MAGIC = b"\x28\xb5\x2f\xfd"
EXAMPLE_LIMIT = 10

NEW = "new"
DUPLICATE = "duplicate"
MISSING = "missing"

# { 'instance' : r"corimh.center0", 'library' : 'IMH', 'module' : 'center01',
#   'module_file' : '/p/center01.sv', 'config_rule' : 'parent cell_s library',
#   'parent_file' : '/p/corimh.sv' }
DUMP_RE = re.compile(
    r"'instance' : r\"(?P<instance>.*?)\", "
    r"'library' : '(?P<library>.*?)', "
    r"'module' : '(?P<module>.*?)', "
    r"'module_file' : '(?P<module_file>.*?)', "
    r"'config_rule' : '(?P<config_rule>.*?)', "
    r"'parent_file' : '(?P<parent_file>.*?)' \}"
)

# instance <hierarchy> liblist <library>;  -- the hierarchy may contain spaces
# (escaped Verilog identifiers are terminated by one), so anchor on the tail.
CFG_RE = re.compile(r"^instance (?P<instance>.*) liblist (?P<library>[^ ;]+) *;")

SOURCE_RE = re.compile(r'^"(?P<path>.*)",\d+$')


def open_text(path: Path) -> IO[str]:
    """Open a text file, decompressing zstd or gzip by magic byte."""
    with open(path, "rb") as probe:
        magic = probe.read(4)
    if magic == ZSTD_MAGIC:
        import zstandard

        stream = zstandard.ZstdDecompressor().stream_reader(open(path, "rb"))
        return io.TextIOWrapper(stream, encoding="utf-8", errors="replace")
    if magic[:2] == GZIP_MAGIC:
        return gzip.open(path, "rt", encoding="utf-8", errors="replace")
    return open(path, encoding="utf-8", errors="replace")


def source_path(value: str) -> str:
    """'"/p/alpha.sv",10' -> '/p/alpha.sv'; the fullchipdump has no line numbers."""
    match = SOURCE_RE.match(value)
    return match.group("path") if match else value


def _record_key(
    instance: str,
    library: str,
    module: str,
    module_file: str,
    config_rule: str,
    parent_file: str,
) -> int:
    return hash(
        (instance, library.upper(), module, module_file, config_rule, parent_file)
    )


def dump_key(match: re.Match[str]) -> int:
    return _record_key(
        match["instance"],
        match["library"],
        match["module"],
        match["module_file"],
        match["config_rule"],
        match["parent_file"],
    )


def xml_fields(record: InstanceRecord) -> tuple[str, str, str, str, str, str]:
    """The XML record as the fullchipdump would have spelled it."""
    definition = record.definition
    return (
        record.instance,
        definition.library,
        definition.module,
        source_path(definition.source),
        # the fullchipdump spells "parent cell's library" as "parent cell_s library"
        definition.configrule.replace("'", "_"),
        source_path(record.instance_source),
    )


def xml_key(record: InstanceRecord) -> int:
    return _record_key(*xml_fields(record))


def xml_record_text(record: InstanceRecord) -> str:
    instance, library, module, module_file, config_rule, parent_file = xml_fields(record)
    return (
        f"{{ 'instance' : r\"{instance}\", 'library' : '{library}', "
        f"'module' : '{module}', 'module_file' : '{module_file}', "
        f"'config_rule' : '{config_rule}', 'parent_file' : '{parent_file}' }}"
    )


def binding_key(instance: str, library: str) -> int:
    return hash((instance, library.upper()))


def dump_line_key(line: str) -> int | None:
    match = DUMP_RE.search(line)
    return dump_key(match) if match else None


def cfg_line_key(line: str) -> int | None:
    match = CFG_RE.match(line)
    return binding_key(match["instance"], match["library"]) if match else None


class HashIndex:
    """A sorted array of int64 hashes; membership by binary search.

    ``take()`` flags the matched slot, so a second XML record hitting the same
    reference record is reported as a duplicate rather than double counted --
    real dumps do contain repeated instances (§6 Q11).
    """

    def __init__(self, values: Iterable[int]) -> None:
        raw = array("q")
        raw.extend(values)
        self.total = len(raw)
        self._data = array("q", sorted(raw))
        self._taken = bytearray(self.total)

    def __len__(self) -> int:
        return self.total

    def __contains__(self, value: int) -> bool:
        data = self._data
        index = bisect_left(data, value)
        return index < len(data) and data[index] == value

    def take(self, value: int) -> str:
        """Return NEW (first match), DUPLICATE (matched before) or MISSING."""
        data = self._data
        index = bisect_left(data, value)
        if index >= len(data) or data[index] != value:
            return MISSING
        if self._taken[index]:
            return DUPLICATE
        self._taken[index] = 1
        return NEW

    def is_taken(self, value: int) -> bool:
        data = self._data
        index = bisect_left(data, value)
        return index < len(data) and data[index] == value and bool(self._taken[index])

    @property
    def matched(self) -> int:
        """Distinct reference records matched at least once."""
        return self._taken.count(1)


def unmatched_lines(
    path: Path,
    index: HashIndex,
    keyer: Callable[[str], int | None],
    limit: int = EXAMPLE_LIMIT,
) -> list[str]:
    """Re-read a reference file to NAME the records the XML pass never matched."""
    found: list[str] = []
    with open_text(path) as handle:
        for line in handle:
            key = keyer(line)
            if key is None or index.is_taken(key):
                continue
            found.append(line.rstrip("\n"))
            if len(found) >= limit:
                break
    return found


def iter_dump_keys(path: Path, log: Callable[[str], None] | None = None) -> Iterator[int]:
    count = 0
    with open_text(path) as handle:
        for line in handle:
            key = dump_line_key(line)
            if key is None:
                continue
            count += 1
            yield key
    if log:
        log(f"fullchipdump: {count:,} instances")


def iter_cfg_keys(path: Path, log: Callable[[str], None] | None = None) -> Iterator[int]:
    count = 0
    with open_text(path) as handle:
        for line in handle:
            key = cfg_line_key(line)
            if key is None:
                continue
            count += 1
            yield key
    if log:
        log(f"{path.name}: {count:,} instances")


@dataclass
class ParanoiaResult:
    xml_instances: int = 0
    dump_instances: int = 0
    xml_only: int = 0
    dump_only: int = 0
    xml_duplicates: int = 0
    cfg_name: str = ""
    cfg_instances: int = 0
    cfg_mismatched: int = 0
    xml_missing_examples: list[str] = field(default_factory=list)
    dump_missing_examples: list[str] = field(default_factory=list)
    cfg_mismatch_examples: list[str] = field(default_factory=list)
    duplicate_examples: list[str] = field(default_factory=list)

    @property
    def differences(self) -> int:
        return self.xml_only + self.dump_only


class ParanoiaChecker:
    """Probes both reference indexes once per XML instance."""

    def __init__(
        self,
        dump_index: HashIndex,
        cfg_index: HashIndex,
        fullchipdump: Path | None = None,
        cfg_sv: Path | None = None,
        limit: int = EXAMPLE_LIMIT,
        log: Callable[[str], None] | None = None,
    ) -> None:
        self._dump = dump_index
        self._cfg = cfg_index
        self._fullchipdump = fullchipdump
        self._cfg_sv = cfg_sv
        self._limit = limit
        self._log = log
        self._xml_instances = 0
        self._xml_only = 0
        self._xml_duplicates = 0
        self._xml_missing_examples: list[str] = []
        self._duplicate_examples: list[str] = []

    def __call__(self, record: InstanceRecord) -> None:
        self._xml_instances += 1
        outcome = self._dump.take(xml_key(record))
        if outcome == MISSING:
            self._xml_only += 1
            if len(self._xml_missing_examples) < self._limit:
                self._xml_missing_examples.append(xml_record_text(record))
        elif outcome == DUPLICATE:
            self._xml_duplicates += 1
            if len(self._duplicate_examples) < self._limit:
                self._duplicate_examples.append(xml_record_text(record))
        self._cfg.take(binding_key(record.instance, record.definition.library))

    def _examples_from(
        self, path: Path | None, index: HashIndex, keyer: Callable[[str], int | None]
    ) -> list[str]:
        if path is None:
            return []
        if self._log:
            self._log(f"re-reading {path.name} for unmatched records")
        return unmatched_lines(path, index, keyer, self._limit)

    def result(self) -> ParanoiaResult:
        dump_only = self._dump.total - self._dump.matched
        cfg_mismatched = self._cfg.total - self._cfg.matched
        return ParanoiaResult(
            xml_instances=self._xml_instances,
            dump_instances=self._dump.total,
            xml_only=self._xml_only,
            dump_only=dump_only,
            xml_duplicates=self._xml_duplicates,
            cfg_name=self._cfg_sv.name if self._cfg_sv else "",
            cfg_instances=self._cfg.total,
            cfg_mismatched=cfg_mismatched,
            xml_missing_examples=list(self._xml_missing_examples),
            dump_missing_examples=(
                self._examples_from(self._fullchipdump, self._dump, dump_line_key)
                if dump_only
                else []
            ),
            cfg_mismatch_examples=(
                self._examples_from(self._cfg_sv, self._cfg, cfg_line_key)
                if cfg_mismatched
                else []
            ),
            duplicate_examples=list(self._duplicate_examples),
        )


def build_checker(
    fullchipdump: Path,
    cfg_sv: Path,
    log: Callable[[str], None] | None = None,
) -> ParanoiaChecker:
    """Read both reference files up front; the XML pass then only probes them."""
    dump_index = HashIndex(iter_dump_keys(fullchipdump, log=log))
    cfg_index = HashIndex(iter_cfg_keys(cfg_sv, log=log))
    return ParanoiaChecker(
        dump_index, cfg_index, fullchipdump=fullchipdump, cfg_sv=cfg_sv, log=log
    )


def _examples(records: list[str]) -> list[str]:
    return [f"      {record}" for record in records]


def paranoia_lines(result: ParanoiaResult) -> list[str]:
    lines = [
        "paranoia results:",
        f"  xml instance count:          {result.xml_instances:,}",
        f"  fullchipdump instance count: {result.dump_instances:,}",
    ]
    if result.differences == 0:
        lines.append("  differences found: none")
    else:
        lines.append(f"  differences found: {result.differences:,}")
        lines.append(f"    xml instances missing from the fullchipdump: {result.xml_only:,}")
        lines += _examples(result.xml_missing_examples)
        lines.append(f"    fullchipdump instances missing from the xml: {result.dump_only:,}")
        lines += _examples(result.dump_missing_examples)
    if result.xml_duplicates:
        lines.append(
            f"  duplicate xml records: {result.xml_duplicates:,}"
            " (same instance and binding emitted more than once; this is the"
            " difference between the two counts above)"
        )
        lines += _examples(result.duplicate_examples)
    lines.append("")
    lines.append(f"  v2k config ({result.cfg_name}) compare")
    lines.append(f"    instances in {result.cfg_name}: {result.cfg_instances:,}")
    lines.append(f"    v2k config binding mismatch from xml: {result.cfg_mismatched:,}")
    lines += _examples(result.cfg_mismatch_examples)
    return lines
