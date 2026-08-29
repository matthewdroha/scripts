"""Module-name patterns read from a --modulefile."""

from __future__ import annotations

import re
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path

from find_collisions.paths import PreflightError

EXACT = "exact"
REGEX = "regex"
PATTERN_FIELDS = ["pattern", "kind", "matched_modules"]

# r"..." (regex, may contain spaces) or a bare whitespace-delimited exact name.
TOKEN_RE = re.compile(r'r"((?:[^"\\]|\\.)*)"|(\S+)')


@dataclass(frozen=True)
class Pattern:
    raw: str
    kind: str
    regex: re.Pattern[str] | None = None

    def matches(self, module: str) -> bool:
        if self.regex is not None:
            return self.regex.search(module) is not None
        return module == self.raw


def parse_patterns(lines: Iterable[str]) -> list[Pattern]:
    """Parse modulefile lines; blank lines and # comments are ignored."""
    patterns: list[Pattern] = []
    for lineno, line in enumerate(lines, start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        for match in TOKEN_RE.finditer(stripped):
            regex_body, exact = match.groups()
            if regex_body is None:
                patterns.append(Pattern(raw=exact, kind=EXACT))
                continue
            try:
                compiled = re.compile(regex_body)
            except re.error as exc:
                raise PreflightError(f"bad regex on line {lineno}: r\"{regex_body}\" ({exc})") from exc
            patterns.append(Pattern(raw=f'r"{regex_body}"', kind=REGEX, regex=compiled))
    return patterns


def load_patterns(path: Path) -> list[Pattern]:
    if not path.is_file():
        raise PreflightError(f"missing module file: {path}")
    with open(path, encoding="utf-8") as handle:
        patterns = parse_patterns(handle)
    if not patterns:
        raise PreflightError(f"no patterns found in module file: {path}")
    return patterns


class Matcher:
    """Memoized any-pattern match; module names repeat across millions of instances."""

    def __init__(self, patterns: Sequence[Pattern]) -> None:
        self._exact = {p.raw for p in patterns if p.kind == EXACT}
        self._regexes = [p.regex for p in patterns if p.regex is not None]
        self._cache: dict[str, bool] = {}

    def __call__(self, module: str) -> bool:
        cached = self._cache.get(module)
        if cached is None:
            cached = module in self._exact or any(r.search(module) for r in self._regexes)
            self._cache[module] = cached
        return cached


def pattern_rows(
    patterns: Sequence[Pattern],
    modules: Iterable[str],
) -> list[dict[str, object]]:
    """One row per pattern, with how many distinct modules it matched."""
    module_list = list(modules)
    return [
        {
            "pattern": pattern.raw,
            "kind": pattern.kind,
            "matched_modules": sum(1 for module in module_list if pattern.matches(module)),
        }
        for pattern in patterns
    ]
