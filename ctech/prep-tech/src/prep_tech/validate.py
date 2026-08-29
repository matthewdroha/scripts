"""Pre-flight validation (spec section 2.4)."""

from __future__ import annotations

import os

from . import discover


def validate_missing_paths(dies: dict) -> None:
    """Fail on input lines that are neither an existing directory nor file."""
    for die, info in dies.items():
        for path in info.get("missing", []):
            raise FileNotFoundError(f"[{die}] input path does not exist: {path}")


def validate_ctech_directories(dies: dict) -> None:
    for die, info in dies.items():
        for path in info.get("ctech_dirs", []):
            if not os.path.isdir(path):
                raise FileNotFoundError(f"[{die}] ctech directory not found: {path}")


def validate_config_files(dies: dict) -> None:
    for die, info in dies.items():
        config_files = info.get("config_files", [])
        if not config_files:
            raise FileNotFoundError(f"[{die}] no configuration file listed")
        for path in config_files:
            if not os.path.isfile(path):
                raise FileNotFoundError(
                    f"[{die}] configuration file not found: {path}"
                )


def validate_regexes(dies: dict) -> None:
    for die, info in dies.items():
        try:
            discover.compile_regexes(info.get("regexes", []))
        except Exception as exc:
            raise ValueError(f"[{die}] invalid REGEX pattern: {exc}") from exc


def validate_output_writable(output_root: str) -> None:
    """Check the nearest existing ancestor of *output_root* is writable."""
    probe = os.path.abspath(output_root)
    while not os.path.exists(probe):
        parent = os.path.dirname(probe)
        if parent == probe:
            break
        probe = parent
    if not os.access(probe, os.W_OK | os.X_OK):
        raise PermissionError(f"output area is not writable: {probe}")


def pre_flight_validation(dies: dict, output_root: str) -> None:
    validate_missing_paths(dies)
    validate_ctech_directories(dies)
    validate_config_files(dies)
    validate_regexes(dies)
    validate_output_writable(output_root)
