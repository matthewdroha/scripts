"""Parse ``prep_tech.input.md`` into a plain dict (spec section 2.1)."""

from __future__ import annotations

import os
import re

_HEADING = re.compile(r"^##\s+(?P<name>\S+)\s+(?P<kind>DIE|IP)\s*$", re.IGNORECASE)
# REGEX=r"..." / REGEX=r'...' -- a raw string literal, taken verbatim for re.search.
_REGEX_SUFFIX = re.compile(
    r"""\s+REGEX\s*=\s*r(?P<quote>["'])(?P<pattern>.*)(?P=quote)\s*$"""
)
_REGEX_ANY = re.compile(r"\s+REGEX\s*=")


class InputFormatError(ValueError):
    """A line in prep_tech.input.md does not follow the documented format."""


def _new_die(kind: str = "die") -> dict:
    return {
        "kind": kind,
        "config_files": [],
        "ctech_dirs": [],
        "regexes": [],
        "regex_pairs": [],
        "missing": [],
    }


def parse_input(path: str) -> dict:
    """Return ``{"dies": {<die>: {kind, config_files, ctech_dirs, regexes,
    regex_pairs, missing}}}``.

    Content lines are classified by filesystem type: an existing directory is a
    ctech structural release area, an existing file is a configuration file.
    Paths that exist as neither are collected under ``missing`` so that
    pre-flight validation can report them.
    """
    dies: dict[str, dict] = {}
    current: dict | None = None

    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip()
            if not line:
                continue

            heading = _HEADING.match(line)
            if heading:
                name = heading.group("name").lower()
                kind = "die"
                if heading.group("kind").upper() == "IP":
                    name += "_ip"
                    kind = "ip"
                current = dies.setdefault(name, _new_die(kind))
                continue

            if line.startswith("#"):
                continue
            if current is None:
                continue

            match = _REGEX_SUFFIX.search(line)
            pattern = None
            if match:
                pattern = match.group("pattern")
                current["regexes"].append(pattern)
                line = line[: match.start()].strip()
            elif _REGEX_ANY.search(line):
                raise InputFormatError(
                    f'{path}: REGEX must be a raw string literal, '
                    f'e.g. REGEX=r"tttt\\S+850v\\S+100c" -- got: {line}'
                )
            if not line:
                continue

            if pattern is not None:
                current["regex_pairs"].append((line, pattern))

            if os.path.isdir(line):
                current["ctech_dirs"].append(line)
            elif os.path.exists(line):
                current["config_files"].append(line)
            else:
                current["missing"].append(line)

    return {"dies": dies}
