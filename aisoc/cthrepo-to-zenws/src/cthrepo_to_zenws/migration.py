"""Parse the zen workspace migration report into path mappings and category rules."""

from __future__ import annotations

import re
from collections import defaultdict
from dataclasses import dataclass
from typing import Callable

_REPO_ROOT_RE = re.compile(r"^Repo root:\s*(\S+)\s*$")
_SRC_RE = re.compile(r"^\s*SRC:\s*(\S+)\s*$")
_DST_RE = re.compile(r"^\s*DST:\s*(\S+)\s*$")

_RULE_SECTIONS = ("--- RTL CATEGORY MAPPING ---", "--- VAL PASS-THROUGH MAPPING ---")
_RULE_RE = re.compile(r"^\s{2,}(\S+)\s+->\s+(\S+)")
_PLACEHOLDER_RE = re.compile(r"<[^>]+>")


def _relative_to(root: str, path: str) -> str | None:
    if root and path.startswith(root + "/"):
        return path[len(root) + 1 :]
    return None


def parse_migration_report(text: str) -> dict[str, str]:
    """Map cheetah-relative source paths to zen-relative destination paths.

    Only SRC/DST pairs whose SRC lies under the report's `Repo root:` are kept;
    the report also lists absolute paths outside the tree that we cannot place.
    """
    root = ""
    mapping: dict[str, str] = {}
    pending_src: str | None = None

    for line in text.splitlines():
        root_match = _REPO_ROOT_RE.match(line)
        if root_match:
            root = root_match.group(1).rstrip("/")
            continue
        src_match = _SRC_RE.match(line)
        if src_match:
            pending_src = src_match.group(1)
            continue
        dst_match = _DST_RE.match(line)
        if dst_match and pending_src is not None:
            src_rel = _relative_to(root, pending_src)
            dst_rel = _relative_to(root, dst_match.group(1))
            if src_rel and dst_rel:
                mapping[src_rel] = dst_rel
            pending_src = None

    return mapping


def parent_dir(path: str) -> str:
    head, sep, _ = path.rpartition("/")
    return head if sep else ""


def directory_map(mapping: dict[str, str]) -> dict[str, str]:
    """Source dir -> dest dir, kept only where every file in it agrees."""
    seen: dict[str, set[str]] = defaultdict(set)
    for src, dst in mapping.items():
        seen[parent_dir(src)].add(parent_dir(dst))
    return {src: next(iter(dsts)) for src, dsts in seen.items() if len(dsts) == 1}


@dataclass(frozen=True)
class CategoryRule:
    source: str
    dest: str
    matcher: Callable[[str], str | None]

    def apply(self, path: str) -> str | None:
        return self.matcher(path)


def _rule_matcher(source: str, dest: str) -> Callable[[str], str | None]:
    """Build a matcher for a `src/rtl/<block>/ -> BLOCKS/<block>/design/rtl/` rule."""
    src_parts = source.strip("/").split("/")
    dest_parts = dest.strip("/").split("/")

    pattern_parts: list[str] = []
    names: list[str] = []
    for part in src_parts:
        placeholder = _PLACEHOLDER_RE.fullmatch(part)
        if placeholder:
            name = f"g{len(names)}"
            names.append(part)
            pattern_parts.append(f"(?P<{name}>[^/]+)")
        else:
            pattern_parts.append(re.escape(part))
    prefix_re = re.compile("^" + "/".join(pattern_parts) + "(?:/(?P<rest>.*))?$")

    def matcher(path: str) -> str | None:
        match = prefix_re.match(path)
        if not match:
            return None
        groups = match.groupdict()
        rest = groups.get("rest") or ""
        out: list[str] = []
        for part in dest_parts:
            if part == "<subpath>":
                if rest:
                    out.append(rest)
                continue
            placeholder = _PLACEHOLDER_RE.fullmatch(part)
            if placeholder:
                index = names.index(part) if part in names else -1
                if index < 0:
                    return None
                out.append(groups[f"g{index}"])
            else:
                out.append(part)
        if rest and "<subpath>" not in dest_parts:
            out.append(rest)
        return "/".join(p for p in out if p)

    return matcher


def parse_category_rules(text: str) -> list[CategoryRule]:
    """Read the category-mapping sections into ordered, unambiguous rules.

    A source prefix listed with two different destinations (for example
    `src/val/vip/`) is dropped rather than guessed at.
    """
    raw: list[tuple[str, str]] = []
    in_section = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped in _RULE_SECTIONS:
            in_section = True
            continue
        if not in_section:
            continue
        if stripped.startswith("---") or not stripped:
            in_section = False
            continue
        match = _RULE_RE.match(line)
        if match:
            raw.append((match.group(1), match.group(2)))

    dests: dict[str, set[str]] = defaultdict(set)
    for source, dest in raw:
        dests[source].add(dest)

    rules: list[CategoryRule] = []
    for source, dest in raw:
        if len(dests[source]) != 1 or "|" in dest:
            continue
        if any(rule.source == source for rule in rules):
            continue
        rules.append(CategoryRule(source, dest, _rule_matcher(source, dest)))

    # Most literal segments first so `src/rtl/common/<block>/` beats `src/rtl/<x>/`.
    rules.sort(
        key=lambda r: sum(1 for p in r.source.strip("/").split("/") if not _PLACEHOLDER_RE.fullmatch(p)),
        reverse=True,
    )
    return rules
