"""Per-die plan building, output rendering, and writing (spec section 3)."""

from __future__ import annotations

import csv
import datetime
import io
import os

from . import discover

SCRIPT_NAME = "prep_tech"

CSV_HEADER = [
    "die",
    "ctech_cell",
    "stdcell name",
    "stdcell library",
    "path to configuration file",
    "path to stdcell verilog",
    "path to ctech verilog",
]

DUPLICATES_CSV_HEADER = [
    "die",
    "stdcell library",
    "stdcell name",
    "configuration file list",
]


# ---------------------------------------------------------------------------
# Plan
# ---------------------------------------------------------------------------


def build_die_plan(die: str, die_info: dict, log=None) -> dict:
    """Resolve one die's configurations and ctech sources into a plan dict."""
    bundles: dict[str, dict] = {}
    cell_index: dict[str, tuple[str, str, str]] = {}  # cell -> (bundle, bmod, config)
    definitions: dict[str, list[tuple[str, str]]] = {}  # cell -> [(config, bundle)]
    prefixes: set[str] = set()

    for config in die_info.get("config_files", []):
        params = discover.parse_cth_file(config)
        prefixes.update(key.lower() for key in discover.lib_keys(params))
        for lib_root in discover.resolve_lib_roots(params):
            if log:
                log(f"{die}: {config} -> {lib_root}")
            for name, bundle in discover.enumerate_bundles(lib_root).items():
                bundles.setdefault(name, bundle)
                for cell in bundle["cells"]:
                    definitions.setdefault(cell, []).append((config, name))
                    cell_index.setdefault(
                        cell, (name, bundle["bmod"], config)
                    )

    duplicates = []
    for cell, defs in sorted(definitions.items()):
        configs = list(dict.fromkeys(config for config, _ in defs))
        if len(configs) < 2:
            continue
        names = list(dict.fromkeys(name for _, name in defs))
        duplicates.append((cell, ":".join(names), ":".join(configs)))

    refs = []
    seen_refs = set()
    unresolved = []
    seen_unresolved = set()
    ctech_cells = set()

    for ctech_dir in die_info.get("ctech_dirs", []):
        for sv_path in discover.find_ctech_sv(ctech_dir):
            ctech_cell, instances = discover.parse_ctech_sv(sv_path)
            ctech_cells.add(ctech_cell)
            for instance in instances:
                found = cell_index.get(instance)
                if found is None:
                    if any(instance.lower().startswith(p) for p in prefixes):
                        key = (ctech_cell, instance)
                        if key not in seen_unresolved:
                            seen_unresolved.add(key)
                            unresolved.append((ctech_cell, instance, sv_path))
                    continue
                bundle_name, bmod, config = found
                key = (ctech_cell, instance, bundle_name)
                if key in seen_refs:
                    continue
                seen_refs.add(key)
                refs.append(
                    (ctech_cell, instance, bundle_name, bmod, sv_path, config)
                )

    return {
        "die": die,
        "bundles": bundles,
        "referenced_keys": {ref[2] for ref in refs},
        "refs": refs,
        "ctech_cells": ctech_cells,
        "unresolved": unresolved,
        "duplicates": duplicates,
        "regexes": list(die_info.get("regexes", [])),
    }


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


def _list_text(paths) -> str:
    return "".join(f"{path}\n" for path in sorted(set(paths)))


def render_die_files(plan: dict) -> dict:
    """Return ``{filename: content}`` for one die's output directory."""
    bundles = plan["bundles"]
    referenced = sorted(plan["referenced_keys"])
    compiled = discover.compile_regexes(plan["regexes"])

    bmods, ndm = [], []
    ctech_lib, ctech_ldb = [], []
    full_lib, full_ldb = [], []
    regex_lib, regex_ldb = [], []

    for name in referenced:
        bundle = bundles[name]
        bmods.extend(bundle.get("bmods") or [bundle["bmod"]])
        ndm.extend(bundle["ndm"])

        lib_nldm = discover.nldm_only(bundle["lib"])
        ldb_nldm = discover.nldm_only(bundle["ldb"])
        full_lib.extend(lib_nldm)
        full_ldb.extend(ldb_nldm)

        selected_lib = discover.select_nldm(bundle["lib"])
        if selected_lib:
            ctech_lib.append(selected_lib)
        selected_ldb = discover.select_nldm(bundle["ldb"])
        if selected_ldb:
            ctech_ldb.append(selected_ldb)

        if compiled:
            regex_lib.extend(discover.regex_filter(lib_nldm, compiled))
            regex_ldb.extend(discover.regex_filter(ldb_nldm, compiled))

    files = {
        "static_stdcells.f": "+define+functional\n" + _list_text(bmods),
        "stdcell.ldb.list.ctech": _list_text(ctech_ldb),
        "stdcell.lib.list.ctech": _list_text(ctech_lib),
        "stdcell.ldb.list": _list_text(full_ldb),
        "stdcell.lib.list": _list_text(full_lib),
        "stdcell.ndm.list": _list_text(ndm),
    }
    if compiled:
        files["stdcell.ldb.list.ctech.regex"] = _list_text(regex_ldb)
        files["stdcell.lib.list.ctech.regex"] = _list_text(regex_lib)
    return files


def _line_count(text: str) -> int:
    return len([line for line in text.splitlines() if line.strip()])


def die_summary(die: str, plan: dict) -> str:
    """One-line per-die summary, printed to STDOUT and repeated in the report."""
    return (
        f"{die}: {len(plan['ctech_cells'])} ctech cells, "
        f"{len(plan['refs'])} referenced stdcells, "
        f"{len(plan['duplicates'])} duplicate definitions, "
        f"{len(plan['unresolved'])} unresolved"
    )


def render_report(plans) -> str:
    """Human-readable per-die report (spec 3.3)."""
    now = datetime.datetime.now().replace(microsecond=0).isoformat()
    lines = [
        f"# script: {SCRIPT_NAME}",
        f"# generated: {now}",
        "#",
        "# summary",
    ]
    for die, plan in plans:
        lines.append(die_summary(die, plan))
    lines.append("")

    for die, plan in plans:
        files = render_die_files(plan)
        lines.append(f"die: {die}")
        lines.append(f"  ctech cells found: {len(plan['ctech_cells'])}")
        lines.append(
            f"  referenced stdcells (deduplicated): {len(plan['refs'])}"
        )
        lines.append(
            f"  duplicate stdcell definitions: {len(plan['duplicates'])}"
        )
        lines.append(
            f"  unresolved stdcell instantiations: {len(plan['unresolved'])}"
        )
        for ctech_cell, stdcell, sv_path in plan["unresolved"]:
            lines.append(f"    {stdcell} <- {ctech_cell} ({sv_path})")
        lines.append(
            "  ctech-referenced .lib files: "
            f"{_line_count(files['stdcell.lib.list.ctech'])}"
        )
        lines.append(
            "  ctech-referenced .ldb/.db files: "
            f"{_line_count(files['stdcell.ldb.list.ctech'])}"
        )
        if plan["regexes"]:
            lines.append(
                "  regex-filtered .lib files: "
                f"{_line_count(files['stdcell.lib.list.ctech.regex'])}"
            )
            lines.append(
                "  regex-filtered .ldb/.db files: "
                f"{_line_count(files['stdcell.ldb.list.ctech.regex'])}"
            )
        lines.append(
            f"  full-list .lib files: {_line_count(files['stdcell.lib.list'])}"
        )
        lines.append(
            f"  full-list .ldb/.db files: {_line_count(files['stdcell.ldb.list'])}"
        )
        lines.append("")

    return "\n".join(lines)


def _csv_text(header, rows) -> str:
    buffer = io.StringIO()
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerow(header)
    writer.writerows(rows)
    return buffer.getvalue()


def render_csv(plans) -> str:
    """Detailed ctech -> stdcell mapping (spec 3.4)."""
    rows = []
    for die, plan in plans:
        for ctech_cell, stdcell, bundle, bmod, sv_path, config in plan["refs"]:
            rows.append([die, ctech_cell, stdcell, bundle, config, bmod, sv_path])
    return _csv_text(CSV_HEADER, rows)


def render_duplicates_csv(plans) -> str:
    """Duplicate stdcell definitions across configuration files (spec 3.5)."""
    rows = []
    for die, plan in plans:
        for cell, bundles, configs in plan["duplicates"]:
            rows.append([die, bundles, cell, configs])
    return _csv_text(DUPLICATES_CSV_HEADER, rows)


# ---------------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------------


def plan_all(parsed: dict, log=None) -> list:
    """Build ``[(die, plan), ...]`` for every die in the parsed input."""
    return [
        (die, build_die_plan(die, info, log=log))
        for die, info in parsed.get("dies", {}).items()
    ]


def planned_outputs(plans, output_root: str) -> list[str]:
    """Every path :func:`generate_all` would write, in write order."""
    paths = [
        os.path.join(output_root, f"{SCRIPT_NAME}.report"),
        os.path.join(output_root, f"{SCRIPT_NAME}.duplicates.csv"),
        os.path.join(output_root, f"{SCRIPT_NAME}.csv"),
    ]
    for die, plan in plans:
        for name in sorted(render_die_files(plan)):
            paths.append(os.path.join(output_root, die, name))
    return paths


def _write(path: str, text: str) -> str:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    return path


def generate_all(
    parsed: dict, output_root: str, allow_duplicates: bool = False, log=None
):
    """Write the output tree. Returns ``(written, plans, has_duplicates)``.

    When duplicates are found and *allow_duplicates* is false, only the report
    and the duplicates CSV are written so the failure can be inspected.
    """
    plans = plan_all(parsed, log=log)
    has_duplicates = any(plan["duplicates"] for _, plan in plans)

    written = [
        _write(
            os.path.join(output_root, f"{SCRIPT_NAME}.report"), render_report(plans)
        ),
        _write(
            os.path.join(output_root, f"{SCRIPT_NAME}.duplicates.csv"),
            render_duplicates_csv(plans),
        ),
    ]
    if has_duplicates and not allow_duplicates:
        return written, plans, has_duplicates

    written.append(
        _write(os.path.join(output_root, f"{SCRIPT_NAME}.csv"), render_csv(plans))
    )
    for die, plan in plans:
        for name, text in sorted(render_die_files(plan).items()):
            if log:
                log(f"writing {die}/{name}")
            written.append(_write(os.path.join(output_root, die, name), text))

    return written, plans, has_duplicates
