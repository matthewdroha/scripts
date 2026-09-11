from __future__ import annotations

from cthrepo_to_zenws.content import change_shape, comment_style, is_binary, normalize_whitespace


def test_comment_style_by_suffix():
    assert comment_style("a/b.sv") == "slash"
    assert comment_style("a/b.cpp") == "slash"
    assert comment_style("a/b.tcl") == "hash"
    assert comment_style("a/Makefile.inc") == "hash"
    assert comment_style("a/b.png") is None


def test_identical_content():
    assert change_shape("a.sv", b"x\n", b"x\n") == "identical"


def test_whitespace_only_change():
    assert change_shape("a.sv", b"module m;\nendmodule\n", b"module m;\n\n   endmodule\n") == "whitespace"


def test_comment_only_change():
    before = b"// old\nmodule m;\nendmodule\n"
    after = b"// brand new comment\nmodule m;\nendmodule\n"
    assert change_shape("a.sv", before, after) == "comment"


def test_block_comment_only_change():
    assert change_shape("a.sv", b"/* a */\nint x;\n", b"/* b */\nint x;\n") == "comment"


def test_code_change():
    assert change_shape("a.sv", b"int x;\n", b"int y;\n") == "code"


def test_binary_change():
    assert change_shape("a.bin", b"\x00\x01", b"\x00\x02") == "binary"


def test_comment_change_in_unknown_suffix_is_code():
    assert change_shape("a.unknown", b"# a\nx\n", b"# b\nx\n") == "code"


def test_is_binary_and_normalize_whitespace():
    assert is_binary(b"a\x00b")
    assert not is_binary(b"plain text")
    assert normalize_whitespace(b"  a  \n\n  b \n") == b"a\nb"
