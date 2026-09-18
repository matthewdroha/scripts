"""Configuration parsing, DesignPackage resolution, bundle discovery, selection.

All paths are treated as vanity paths: nothing here calls ``os.path.realpath``.
"""

from __future__ import annotations

import gzip
import os
import re

# ---------------------------------------------------------------------------
# Configuration file parsing (spec 2.3)
# ---------------------------------------------------------------------------

_SECTION = re.compile(r"^\s*\[(?P<name>[^\]]+)\]\s*$")
_FIELD = re.compile(r"^\s*(?P<key>[A-Za-z_][\w.]*)\s*=\s*(?P<value>.*?)\s*$")
_TOKEN = re.compile(r"designpackage\(\s*name\s*=\s*[^,)]*,\s*(?P<field>[^)\s]+)\s*\)")
# '_' is a word character, so key/pitch tokens are delimited explicitly.
_LIB_COMPONENT = re.compile(r"/lib\d+_(?P<key>[A-Za-z][A-Za-z0-9]*)_")
_PITCH = re.compile(r"(?:^|_)(?P<pitch>\d+pp)(?:_|$)")

#: ``[DESIGNPACKAGE]`` fields that never name a stdcell library.
NON_STDCELL_FIELDS = frozenset(
    {"esd_lib", "cpipad_lib", "path", "version", "name", "lib_name", "lib_height_class"}
)

_MAX_TOKEN_PASSES = 32


def parse_cth_file(path: str) -> dict:
    """Return the ``[DESIGNPACKAGE]`` fields of a Cheetah configuration file.

    Keys keep their original case; look them up with :func:`get_param`.
    """
    params: dict[str, str] = {}
    in_section = False
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            section = _SECTION.match(line)
            if section:
                in_section = section.group("name").strip().upper() == "DESIGNPACKAGE"
                continue
            if not in_section:
                continue
            field = _FIELD.match(line)
            if field:
                params.setdefault(field.group("key"), field.group("value"))
    return params


def get_param(params: dict, key: str) -> str | None:
    """Case-insensitive field lookup."""
    if key in params:
        return params[key]
    lowered = key.lower()
    for name, value in params.items():
        if name.lower() == lowered:
            return value
    return None


def resolve_design_package(value: str, params: dict) -> str:
    """Recursively substitute ``designpackage(name=<pkg>,<field>)`` tokens."""
    for _ in range(_MAX_TOKEN_PASSES):
        match = _TOKEN.search(value)
        if match is None:
            return value
        field = match.group("field")
        replacement = get_param(params, field)
        if replacement is None:
            raise KeyError(f"designpackage field not found: {field}")
        value = value[: match.start()] + replacement + value[match.end() :]
    raise ValueError(f"designpackage token substitution did not converge: {value}")


def lib_keys(params: dict) -> list[str]:
    """Stdcell library keys for a configuration (``LIB_NAME`` split, or auto-detect)."""
    lib_name = get_param(params, "lib_name")
    if lib_name:
        return [part for part in lib_name.split("_") if part]

    detected = []
    for key, value in params.items():
        if key.lower() in NON_STDCELL_FIELDS:
            continue
        for match in _LIB_COMPONENT.finditer(value):
            if match.group("key").lower() == key.lower():
                detected.append(key)
                break
    return sorted(detected)


def _discover_contour_root(key: str, params: dict) -> str:
    """Find ``lib*_<key>_*_fv`` under the resolved ``path`` (spec 2.3, contour style)."""
    base = get_param(params, "path")
    if not base:
        raise FileNotFoundError(f"no library field and no 'path' for lib_name '{key}'")
    base = resolve_design_package(base, params)

    height_class = get_param(params, "lib_height_class") or ""
    pitch_match = _PITCH.search(height_class)
    pitch = pitch_match.group("pitch") if pitch_match else None

    try:
        entries = sorted(os.listdir(base))
    except OSError as exc:
        raise FileNotFoundError(f"cannot list design package path: {base}") from exc

    candidates = [
        name
        for name in entries
        if name.startswith("lib")
        and f"_{key}_" in name
        and name.endswith("_fv")
        and (pitch is None or f"_{pitch}" in name)
    ]
    if not candidates:
        raise FileNotFoundError(
            f"no stdcell library directory for '{key}' under {base}"
        )
    return os.path.join(base, candidates[0])


def resolve_lib_roots(params: dict) -> list[str]:
    """Resolve every stdcell library key of a configuration to its library root."""
    roots = []
    for key in lib_keys(params):
        value = get_param(params, key)
        if value:
            roots.append(resolve_design_package(value, params))
        else:
            roots.append(_discover_contour_root(key, params))
    return roots


def resolve_lib_root(params: dict) -> str:
    """First resolved library root (convenience for single-library configurations)."""
    roots = resolve_lib_roots(params)
    if not roots:
        raise FileNotFoundError("no stdcell library key found in [DESIGNPACKAGE]")
    return roots[0]


# ---------------------------------------------------------------------------
# ctech SystemVerilog parsing
# ---------------------------------------------------------------------------

_BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
_LINE_COMMENT = re.compile(r"//[^\n]*")
_MODULE = re.compile(r"\bmodule\s+(\w+)")
_INSTANCE = re.compile(r"^[ \t]*(?P<type>\w+)\s+(?P<inst>\w+)\s*\(", re.MULTILINE)

_SV_KEYWORDS = frozenset(
    """
    module endmodule macromodule primitive endprimitive interface endinterface
    package endpackage program endprogram class endclass function endfunction
    task endtask generate endgenerate begin end fork join case casex casez
    endcase if else for while do repeat forever return break continue
    always always_comb always_ff always_latch initial final assign alias
    input output inout ref wire tri triand trior wand wor logic bit reg
    integer int shortint longint byte real shortreal time realtime string
    event chandle enum struct union typedef localparam parameter defparam
    genvar supply0 supply1 signed unsigned static automatic const var
    posedge negedge default assert assume cover property sequence
    """.split()
)


def _strip_comments(text: str) -> str:
    return _LINE_COMMENT.sub("", _BLOCK_COMMENT.sub("", text))


def parse_ctech_sv(path: str) -> tuple[str, list[str]]:
    """Return ``(module_name, [instantiated_type, ...])`` for a ctech ``.sv`` file."""
    with open(path, encoding="utf-8", errors="replace") as handle:
        text = _strip_comments(handle.read())

    module = _MODULE.search(text)
    name = module.group(1) if module else os.path.splitext(os.path.basename(path))[0]

    seen: list[str] = []
    for match in _INSTANCE.finditer(text):
        kind = match.group("type")
        if kind in _SV_KEYWORDS or match.group("inst") in _SV_KEYWORDS:
            continue
        if kind not in seen:
            seen.append(kind)
    return name, seen


def find_ctech_sv(directory: str) -> list[str]:
    """ctech cell sources directly in *directory* (``ctech_lib*.sv``), sorted."""
    return [
        os.path.join(directory, name)
        for name in sorted(os.listdir(directory))
        if name.startswith("ctech_lib")
        and name.endswith(".sv")
        and os.path.isfile(os.path.join(directory, name))
    ]


# ---------------------------------------------------------------------------
# Bundle enumeration
# ---------------------------------------------------------------------------

_BMOD_MODULE = re.compile(r"^\s*module\s+(\w+)", re.MULTILINE)


def _open_maybe_gz(path: str):
    if path.endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8", errors="replace")
    return open(path, encoding="utf-8", errors="replace")


def parse_bmod_cells(path: str) -> set[str]:
    """Stdcell module names defined by a ``*bmod.v`` file.

    Streamed line by line: release bmod files run to several MB each and a die
    can pull in hundreds of them.
    """
    cells: set[str] = set()
    in_block_comment = False
    with _open_maybe_gz(path) as handle:
        for line in handle:
            if in_block_comment:
                end = line.find("*/")
                if end < 0:
                    continue
                line = line[end + 2 :]
            start = line.find("/*")
            if start >= 0:
                in_block_comment = line.find("*/", start) < 0
                line = line[:start] if in_block_comment else _BLOCK_COMMENT.sub("", line)
            match = _BMOD_MODULE.match(_LINE_COMMENT.sub("", line))
            if match:
                cells.add(match.group(1))
    return cells


def _classify_collateral(name: str) -> str | None:
    if re.search(r"\.lib(\.gz)?$", name):
        return "lib"
    if re.search(r"\.ldb(\.gz)?$", name):
        return "ldb"
    if re.search(r"\.db(\.gz)?$", name):
        return "db"
    return None


def _collect_lib_dir(lib_dir: str) -> tuple[list[str], list[str]]:
    """Return ``(lib_files, ldb_files)``; ``.ldb`` wins over a same-stem ``.db``."""
    libs: list[str] = []
    ldbs: dict[str, str] = {}
    dbs: dict[str, str] = {}
    if not os.path.isdir(lib_dir):
        return [], []
    for name in sorted(os.listdir(lib_dir)):
        full = os.path.join(lib_dir, name)
        if not os.path.isfile(full):
            continue
        kind = _classify_collateral(name)
        if kind == "lib":
            libs.append(full)
        elif kind == "ldb":
            ldbs[re.sub(r"\.ldb(\.gz)?$", "", name)] = full
        elif kind == "db":
            dbs[re.sub(r"\.db(\.gz)?$", "", name)] = full
    merged = dict(dbs)
    merged.update(ldbs)
    return sorted(libs), sorted(merged.values())


_BUNDLE_CACHE: dict[str, dict] = {}


def enumerate_bundles(lib_root: str) -> dict:
    """Map bundle directory name -> ``{root, bmod, bmods, cells, lib, ldb, ndm}``.

    A directory is a bundle only when it holds a ``verilog/*bmod.v`` file.
    Results are cached: dies routinely share a library root, and each root costs
    hundreds of multi-MB reads over NFS.
    """
    cached = _BUNDLE_CACHE.get(lib_root)
    if cached is not None:
        return cached

    bundles: dict[str, dict] = {}
    if not os.path.isdir(lib_root):
        return bundles

    for name in sorted(os.listdir(lib_root)):
        root = os.path.join(lib_root, name)
        verilog = os.path.join(root, "verilog")
        if not os.path.isdir(verilog):
            continue
        bmods = sorted(
            os.path.join(verilog, entry)
            for entry in os.listdir(verilog)
            if entry.endswith("bmod.v") or entry.endswith("bmod.v.gz")
        )
        if not bmods:
            continue

        cells: set[str] = set()
        for bmod in bmods:
            cells |= parse_bmod_cells(bmod)

        libs, ldbs = _collect_lib_dir(os.path.join(root, "lib"))
        ndm_dir = os.path.join(root, "ndm")
        # ndm/ also holds label and rule .tcl sidecars; only the .ndm is a list entry.
        ndm = (
            sorted(
                os.path.join(ndm_dir, entry)
                for entry in os.listdir(ndm_dir)
                if entry.endswith(".ndm")
            )
            if os.path.isdir(ndm_dir)
            else []
        )

        bundles[name] = {
            "root": root,
            "bmod": bmods[0],
            "bmods": bmods,
            "cells": cells,
            "lib": libs,
            "ldb": ldbs,
            "ndm": ndm,
        }
    _BUNDLE_CACHE[lib_root] = bundles
    return bundles


# ---------------------------------------------------------------------------
# PVT + nldm selection (spec section 4)
# ---------------------------------------------------------------------------

TARGET_PROCESS = "tttt"
TARGET_VOLTAGE = 0.650
TARGET_TEMPERATURE = 100.0

_VOLTAGE = re.compile(r"_(?P<whole>\d+)p(?P<frac>\d+)v")
_TEMPERATURE = re.compile(r"_(?P<sign>m?)(?P<value>\d+)c")


def nldm_only(files) -> list[str]:
    """Keep only nldm-format collateral."""
    return [path for path in files if "nldm" in os.path.basename(path)]


def _pvt_distance(path: str) -> tuple:
    name = os.path.basename(path)

    voltage = _VOLTAGE.search(name)
    if voltage:
        volts = float(f"{voltage.group('whole')}.{voltage.group('frac')}")
        voltage_delta = abs(volts - TARGET_VOLTAGE)
        # The process corner is the token immediately before the first voltage;
        # a second 'tttt' later in the name is the RC corner, not the process.
        head = name[: voltage.start()].rsplit("_", 1)
        process = head[-1] if head else ""
    else:
        voltage_delta = float("inf")
        process = ""
    process_penalty = 0 if process == TARGET_PROCESS else 1

    temperature = _TEMPERATURE.search(name)
    if temperature:
        degrees = float(temperature.group("value"))
        if temperature.group("sign"):
            degrees = -degrees
        temperature_delta = abs(degrees - TARGET_TEMPERATURE)
    else:
        temperature_delta = float("inf")

    return (process_penalty, voltage_delta, temperature_delta, name)


def select_nldm(files) -> str | None:
    """The single nldm file closest to tttt / 0.650V / 100C; ``None`` if no nldm."""
    candidates = nldm_only(files)
    if not candidates:
        return None
    return min(candidates, key=_pvt_distance)


# ---------------------------------------------------------------------------
# REGEX collateral filtering (spec 3.0 / Q10)
# ---------------------------------------------------------------------------


def compile_regexes(patterns) -> list:
    """Compile die ``REGEX=`` patterns; invalid patterns raise ``re.error``."""
    return [re.compile(pattern) for pattern in patterns]


def regex_filter(files, compiled) -> list[str]:
    """Files whose basename matches any compiled pattern (union / logical OR)."""
    if not compiled:
        return []
    return [
        path
        for path in files
        if any(pattern.search(os.path.basename(path)) for pattern in compiled)
    ]
