"""Collision derivation rules for the raw and reduced reports."""

from __future__ import annotations

import os
import re
from collections import Counter, defaultdict
from collections.abc import Iterable

from find_collisions.xmlstream import Definition, InstanceRecord

RAW_FIELDS = ["module", "library", "configrule", "source", "instance_count"]
INSTANCE_FIELDS = [
    "module",
    "library",
    "configrule",
    "source",
    "instance",
    "instance_source",
]
REDUCED_BASE_FIELDS = [
    "module",
    "source",
    "library_count",
    "config_rule_count",
    "instance_count",
]

SOURCE_RE = re.compile(r'^"(.*)",(\d+)$')


def colliding_modules(counts: Counter[Definition]) -> set[str]:
    """Modules bound to more than one distinct (library, configrule, source)."""
    seen: defaultdict[str, set[tuple[str, str, str]]] = defaultdict(set)
    for definition in counts:
        seen[definition.module].add(
            (definition.library, definition.configrule, definition.source)
        )
    return {module for module, combos in seen.items() if len(combos) > 1}


def modules_with_multiple_sources(counts: Counter[Definition]) -> set[str]:
    """Modules with more than one distinct source; always a subset of colliding_modules."""
    seen: defaultdict[str, set[str]] = defaultdict(set)
    for definition in counts:
        seen[definition.module].add(definition.source)
    return {module for module, sources in seen.items() if len(sources) > 1}


def all_configrule_values(counts: Counter[Definition]) -> list[str]:
    """Every distinct configrule in the whole dump, sorted for a stable column order."""
    return sorted({definition.configrule for definition in counts})


def filter_counts(counts: Counter[Definition], modules: Iterable[str]) -> Counter[Definition]:
    """Restrict counts to the named modules; the per-module rules are unaffected."""
    wanted = set(modules)
    return Counter(
        {
            definition: count
            for definition, count in counts.items()
            if definition.module in wanted
        }
    )


def collect_instance_rows(records: Iterable[InstanceRecord]) -> list[dict[str, object]]:
    """Flatten captured instance records, sorted by module then instance path."""
    rows = [
        {
            "module": record.definition.module,
            "library": record.definition.library,
            "configrule": record.definition.configrule,
            "source": record.definition.source,
            "instance": record.instance,
            "instance_source": record.instance_source,
        }
        for record in records
    ]
    rows.sort(key=lambda row: (row["module"], row["instance"]))  # type: ignore[index]
    return rows


def canonicalize_source(source: str) -> str:
    """Resolve the path inside a `"<path>",<line>` source string via realpath."""
    match = SOURCE_RE.match(source)
    if not match:
        return source
    path, line = match.groups()
    return f'"{os.path.realpath(path)}",{line}'


def build_realpath_counts(
    counts: Counter[Definition],
    modules: Iterable[str] | None = None,
) -> Counter[Definition]:
    """Re-key counts on realpath-collapsed sources, merging tuples that now match."""
    wanted = None if modules is None else set(modules)
    cache: dict[str, str] = {}
    merged: Counter[Definition] = Counter()
    for definition, count in counts.items():
        if wanted is not None and definition.module not in wanted:
            continue
        canonical = cache.get(definition.source)
        if canonical is None:
            canonical = canonicalize_source(definition.source)
            cache[definition.source] = canonical
        merged[definition._replace(source=canonical)] += count
    return merged


def collect_raw_rows(counts: Counter[Definition]) -> list[dict[str, object]]:
    """One row per distinct definition of every colliding module (section 3.2)."""
    colliding = colliding_modules(counts)
    rows = [
        {
            "module": definition.module,
            "library": definition.library,
            "configrule": definition.configrule,
            "source": definition.source,
            "instance_count": count,
        }
        for definition, count in counts.items()
        if definition.module in colliding
    ]
    rows.sort(key=lambda row: (row["module"], -row["instance_count"]))  # type: ignore[operator]
    return rows


def collect_reduced_rows(
    counts: Counter[Definition],
    all_configrules: Iterable[str] | None = None,
) -> list[dict[str, object]]:
    """One row per module+source, for modules with >1 distinct source (section 3.3)."""
    qualifying = modules_with_multiple_sources(counts)
    grouped: defaultdict[tuple[str, str], dict[str, object]] = defaultdict(
        lambda: {"libraries": set(), "configrules": set(), "instance_count": 0}
    )
    for definition, count in counts.items():
        if definition.module not in qualifying:
            continue
        entry = grouped[(definition.module, definition.source)]
        entry["libraries"].add(definition.library)  # type: ignore[union-attr]
        entry["configrules"].add(definition.configrule)  # type: ignore[union-attr]
        entry["instance_count"] += count  # type: ignore[operator]

    configrule_columns = list(all_configrules) if all_configrules is not None else []
    rows: list[dict[str, object]] = []
    for (module, source), entry in grouped.items():
        configrules: set[str] = entry["configrules"]  # type: ignore[assignment]
        row: dict[str, object] = {
            "module": module,
            "source": source,
            "library_count": len(entry["libraries"]),  # type: ignore[arg-type]
            "config_rule_count": len(configrules),
            "instance_count": entry["instance_count"],
        }
        for configrule in configrule_columns:
            row[configrule] = 1 if configrule in configrules else 0
        rows.append(row)
    rows.sort(key=lambda row: (row["module"], -row["instance_count"]))  # type: ignore[operator]
    return rows


def reduced_fields(all_configrules: Iterable[str] | None = None) -> list[str]:
    return REDUCED_BASE_FIELDS + (list(all_configrules) if all_configrules else [])
