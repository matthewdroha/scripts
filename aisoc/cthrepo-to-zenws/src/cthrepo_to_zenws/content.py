"""Classify how a file's content changed, so obvious grafts can be automated."""

from __future__ import annotations

import re

_SLASH_COMMENT_SUFFIXES = {".c", ".cc", ".cpp", ".h", ".hpp", ".sv", ".svh", ".v", ".vh"}
_HASH_COMMENT_SUFFIXES = {
    ".cfg",
    ".cth",
    ".f",
    ".list",
    ".mk",
    ".pl",
    ".pm",
    ".py",
    ".sh",
    ".tcl",
    ".yaml",
    ".yml",
}

_BLOCK_COMMENT_RE = re.compile(rb"/\*.*?\*/", re.DOTALL)
_LINE_COMMENT_RE = re.compile(rb"//[^\n]*")
_HASH_COMMENT_RE = re.compile(rb"#[^\n]*")


def suffix_of(path: str) -> str:
    name = path.rsplit("/", 1)[-1]
    dot = name.rfind(".")
    return name[dot:].lower() if dot > 0 else ""


def comment_style(path: str) -> str | None:
    """"slash", "hash" or None when comments cannot be stripped safely."""
    suffix = suffix_of(path)
    if suffix in _SLASH_COMMENT_SUFFIXES:
        return "slash"
    if suffix in _HASH_COMMENT_SUFFIXES:
        return "hash"
    if path.rsplit("/", 1)[-1].startswith("Makefile"):
        return "hash"
    return None


def is_binary(data: bytes) -> bool:
    return b"\x00" in data[:8000]


def strip_comments(data: bytes, style: str) -> bytes:
    if style == "slash":
        data = _BLOCK_COMMENT_RE.sub(b" ", data)
        return _LINE_COMMENT_RE.sub(b"", data)
    return _HASH_COMMENT_RE.sub(b"", data)


def normalize_whitespace(data: bytes) -> bytes:
    return b"\n".join(line.strip() for line in data.split(b"\n") if line.strip())


def change_shape(path: str, before: bytes, after: bytes) -> str:
    """One of identical, whitespace, comment, binary or code."""
    if before == after:
        return "identical"
    if is_binary(before) or is_binary(after):
        return "binary"
    if normalize_whitespace(before) == normalize_whitespace(after):
        return "whitespace"
    style = comment_style(path)
    if style:
        lhs = normalize_whitespace(strip_comments(before, style))
        rhs = normalize_whitespace(strip_comments(after, style))
        if lhs == rhs:
            return "comment"
    return "code"
