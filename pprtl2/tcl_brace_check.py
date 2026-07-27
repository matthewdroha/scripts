#!/usr/bin/env python3
r"""tcl_brace_check.py - Tcl/SDC brace & bracket balance checker.

Detects unmatched/mismatched `{}` and `[]` in Tcl (including SDC) source
files, without falling into the common false-positive trap of naive
bracket-matchers.

Tcl parsing rules this checker honors:
  - A backslash escapes the following character everywhere (the escaped
    character is never treated as a delimiter).
  - Inside a brace-quoted word (`{...}`), only *unescaped* `{` and `}`
    matter for finding the matching close brace. Everything else --
    `[`, `]`, `$`, `"`, spaces, etc. -- is completely literal and is
    NOT tracked. (This is why naive checkers choke on things like
    `regsub {\[get_pins\s+\{(\S+)\}\]}  ...`.)
  - Outside of braces, `"..."` starts/stops a double-quoted string in
    which `{`/`}`/`[`/`]` are not structural.
  - Outside of braces/strings, `[` `]` delimit command substitution and
    are tracked on their own stack.
  - A line whose first non-whitespace character is `#` is a full-line
    Tcl comment (and is skipped) UNLESS we are currently inside an
    open brace-word, in which case `#` is just literal text.

Usage:
    tcl_brace_check.py FILE [FILE ...]
    tcl_brace_check.py --context 2 FILE

Exit status:
    0  no issues found in any file
    1  one or more issues found
    2  usage / file error
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass


@dataclass
class Issue:
    kind: str        # "unmatched_open" | "unmatched_close"
    char: str        # the delimiter character involved
    line: int
    col: int
    opened_line: int | None = None
    opened_col: int | None = None

    def describe(self) -> str:
        if self.kind == "unmatched_close":
            return f"line {self.line} col {self.col}: unmatched closing '{self.char}' (no open '{{'/'[' to match)"
        return f"line {self.line} col {self.col}: unclosed '{self.char}' (never closed before end of file)"


def check_text(lines: list[str]) -> list[Issue]:
    """Return a list of Issues describing brace/bracket imbalances.

    `lines` should include line terminators (as returned by
    `file.readlines()`) but that isn't required for correctness.
    """
    brace_stack: list[tuple[int, int]] = []
    bracket_stack: list[tuple[int, int]] = []
    in_string = False
    issues: list[Issue] = []

    for lineno, line in enumerate(lines, 1):
        stripped = line.lstrip()
        if stripped.startswith("#") and not brace_stack:
            continue

        i = 0
        n = len(line)
        while i < n:
            c = line[i]

            if c == "\\" and i + 1 < n:
                i += 2
                continue

            if brace_stack:
                # Inside a brace-word: only { and } are structural.
                if c == "{":
                    brace_stack.append((lineno, i + 1))
                elif c == "}":
                    brace_stack.pop()
                i += 1
                continue

            if c == '"':
                in_string = not in_string
                i += 1
                continue
            if in_string:
                i += 1
                continue
            if c == "#":
                break  # rest of line is a comment

            if c == "{":
                brace_stack.append((lineno, i + 1))
            elif c == "}":
                issues.append(Issue("unmatched_close", "}", lineno, i + 1))
            elif c == "[":
                bracket_stack.append((lineno, i + 1))
            elif c == "]":
                if bracket_stack:
                    bracket_stack.pop()
                else:
                    issues.append(Issue("unmatched_close", "]", lineno, i + 1))
            i += 1

    for (oline, ocol) in brace_stack:
        issues.append(Issue("unmatched_open", "{", oline, ocol))
    for (oline, ocol) in bracket_stack:
        issues.append(Issue("unmatched_open", "[", oline, ocol))

    return issues


def check_file(path: str) -> list[Issue]:
    with open(path, "r", errors="replace") as f:
        lines = f.readlines()
    return check_text(lines)


def print_context(path: str, lineno: int, context: int) -> None:
    if context <= 0:
        return
    with open(path, "r", errors="replace") as f:
        lines = f.readlines()
    start = max(1, lineno - context)
    end = min(len(lines), lineno + context)
    for n in range(start, end + 1):
        marker = ">>" if n == lineno else "  "
        print(f"    {marker} {n:>6}: {lines[n - 1].rstrip()}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Detect unmatched/mismatched braces and brackets in Tcl/SDC files."
    )
    parser.add_argument("files", nargs="+", help="Tcl/SDC file(s) to check")
    parser.add_argument(
        "-c", "--context", type=int, default=0,
        help="number of surrounding lines to print around each issue (default: 0)",
    )
    args = parser.parse_args(argv)

    any_issues = False
    for path in args.files:
        try:
            issues = check_file(path)
        except OSError as e:
            print(f"{path}: error: {e}", file=sys.stderr)
            any_issues = True
            continue

        if not issues:
            print(f"{path}: OK ({sum(1 for _ in open(path, errors='replace'))} lines, no brace/bracket issues found)")
            continue

        any_issues = True
        print(f"{path}: {len(issues)} issue(s) found")
        for issue in issues:
            print(f"  - {issue.describe()}")
            print_context(path, issue.line, args.context)

    return 1 if any_issues else 0


if __name__ == "__main__":
    sys.exit(main())
