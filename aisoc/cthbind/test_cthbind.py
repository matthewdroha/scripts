#!/usr/bin/env python3
"""Unit tests for cthbind (spec test plan tests 1-5, 7).

Run:  python3 test_cthbind.py
  or: python3 -m unittest test_cthbind -v
"""

from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from pathlib import Path

import cthbind as cb

SAMPLE_QUERY_OUTPUT = """\
[Envs]
\tCHEETAH_RTL_ROOT = /p/hdk/cad/Cheetah-RTL/2026.06.p02
\tPATH = /p/hdk/rtl/cad/x86-64_linux26/synopsys/vcsmx/X-2025.06-SP2/bin:.:/usr/bin:/bin

[ToolVersion]
\tVCS_VERSION = X-2025.06-SP2
[ToolVersion_sles15sp7]

[License]
\tFeature = synopsys/vcs
\tMode = append
[License]
\tFeature = synopsys/verdi
\tMode = append
[License]
\tFeature = synopsys/vcs
\tMode = append
"""


class TestParseCthQueryOutput(unittest.TestCase):
    """Spec test 1 — INI parsing."""

    def test_sections_and_case_insensitive_headers(self) -> None:
        rows = cb.parse_cth_query_output(SAMPLE_QUERY_OUTPUT)
        sections = {r[0] for r in rows}
        self.assertIn("ENVS", sections)
        self.assertIn("TOOLVERSION", sections)
        self.assertIn("LICENSE", sections)
        self.assertNotIn("TOOLVERSION_SLES15SP7", sections)  # empty section, no rows

    def test_license_only_feature_key(self) -> None:
        rows = cb.parse_cth_query_output(SAMPLE_QUERY_OUTPUT)
        license_rows = [r for r in rows if r[0] == "LICENSE"]
        self.assertTrue(all(k == "Feature" for _, k, _ in license_rows))

    def test_rows_for_flow_dedups_repeated_license_feature(self) -> None:
        rows = cb.rows_for_flow("vcs", SAMPLE_QUERY_OUTPUT)
        features = [r.value for r in rows if r.section == "LICENSE"]
        self.assertEqual(features, ["synopsys/vcs", "synopsys/verdi"])

    def test_walrus_separator_supported(self) -> None:
        text = "[Envs]\n\tdefault_python_version := 3.13.2   \n"
        rows = cb.parse_cth_query_output(text)
        self.assertEqual(rows, [("ENVS", "default_python_version", "3.13.2")])

    def test_walrus_and_equals_separators_mixed_in_same_section(self) -> None:
        text = "[Envs]\n\tFOO = /bar\n\tBAZ := 1.2.3\n"
        rows = cb.parse_cth_query_output(text)
        self.assertEqual(rows, [("ENVS", "FOO", "/bar"), ("ENVS", "BAZ", "1.2.3")])


class TestDirectoryDetection(unittest.TestCase):
    """Spec test 2 — directory detection & PATH splitting."""

    def test_plain_path_is_candidate(self) -> None:
        self.assertEqual(cb.bindings_candidates("/p/hdk/cad/foo/1.0"), ["/p/hdk/cad/foo/1.0"])

    def test_version_string_is_not_candidate(self) -> None:
        self.assertEqual(cb.bindings_candidates("X-2025.06-SP2"), [])

    def test_path_style_splits_and_filters_noise(self) -> None:
        value = "/p/hdk/cad/foo/bin:.:/usr/bin:/bin:/p/hdk/cad/bar/lib"
        self.assertEqual(
            cb.bindings_candidates(value),
            ["/p/hdk/cad/foo/bin", "/p/hdk/cad/bar/lib"],
        )

    def test_existence_check_entries_includes_relative_dot(self) -> None:
        value = "/p/hdk/cad/foo/bin:.:/usr/bin"
        self.assertEqual(cb.existence_check_entries(value), ["/p/hdk/cad/foo/bin", ".", "/usr/bin"])

    def test_existence_check_entries_skips_non_path_scalar(self) -> None:
        self.assertEqual(cb.existence_check_entries("X-2025.06-SP2"), [])


class TestDedupAndCommentGeneration(unittest.TestCase):
    """Spec test 3 — dedup & comment generation."""

    def test_shared_directory_gets_both_flows_in_order(self) -> None:
        rows = [
            cb.QueryRow(flow="vcssim", section="ENVS", key="VCS_HOME", value="/p/hdk/rtl/cad/vcsmx/X-2025.06-SP2"),
            cb.QueryRow(flow="vcs", section="ENVS", key="VCS_HOME", value="/p/hdk/rtl/cad/vcsmx/X-2025.06-SP2"),
            cb.QueryRow(flow="vcs", section="ENVS", key="OTHER", value="/p/hdk/rtl/cad/other/1.0"),
        ]
        additions = cb.build_bindings_additions(rows)
        self.assertEqual(len(additions), 2)
        self.assertEqual(additions[0].directory, "/p/hdk/rtl/cad/vcsmx/X-2025.06-SP2")
        self.assertEqual(additions[0].flows, ["vcssim", "vcs"])

    def test_render_block_is_quoted_with_flow_comment(self) -> None:
        entries = [cb.BindingEntry(directory="/p/hdk/cad/foo/1.0", flows=["vcssim", "vcs"])]
        lines = cb.render_addition_block(entries)
        self.assertIn("  # Registered by flows: vcssim vcs", lines)
        self.assertIn('  - "/p/hdk/cad/foo/1.0"', lines)
        self.assertEqual(lines[0], "  # Start cthbind additions")
        self.assertEqual(lines[-1], "  # Finish cthbind additions")


FIXTURE_YAML = """\
defaults:
  image: "foo.sif"

bindings_tools:
  - "/p/hdk/cad/existing/1.0"
  # a comment

bindings_design:
  - "/p/gtkit/libs/tech/1.0"
"""


class TestYamlInsertion(unittest.TestCase):
    """Spec test 4 — yaml bindings_tools insertion."""

    def test_new_block_appended_at_end_of_bindings_tools_only(self) -> None:
        entries = [cb.BindingEntry(directory="/p/hdk/cad/new/2.0", flows=["vcs"])]
        block = cb.render_addition_block(entries)
        new_text = cb.insert_cthbind_block(FIXTURE_YAML, block)

        pre_design, _, post_design = new_text.partition("bindings_design:")
        self.assertIn('  - "/p/hdk/cad/existing/1.0"', pre_design)
        self.assertIn("  # Start cthbind additions", pre_design)
        self.assertIn('  - "/p/hdk/cad/new/2.0"', pre_design)
        self.assertIn("  # Finish cthbind additions", pre_design)
        self.assertTrue(post_design.strip().startswith('- "/p/gtkit/libs/tech/1.0"'))

    def test_missing_bindings_tools_section_raises(self) -> None:
        with self.assertRaises(ValueError):
            cb.insert_cthbind_block("defaults:\n  image: foo\n", ["# x"])


EXISTING_BINDINGS_YAML = """\
defaults:
  image: "foo.sif"

bindings_tools:
  - "/p/hdk/cad/existing/1.0"
  # a comment
  - "/nfs/site/disks/ipx_prd_pic_001:/p/ipx/ipcache2"
  - /p/hdk/cad/unquoted/2.0
  - "/p/hdk/cad/trailing/3.0/"

bindings_design:
  - "/p/gtkit/libs/tech/1.0"
"""


class TestExistingYamlFilter(unittest.TestCase):
    """Filter out candidates already present in the original yaml's bindings_tools:."""

    def test_parse_existing_bindings_tools_extracts_source_paths(self) -> None:
        existing = cb.parse_existing_bindings_tools(EXISTING_BINDINGS_YAML)
        self.assertEqual(
            existing,
            {
                "/p/hdk/cad/existing/1.0",
                "/nfs/site/disks/ipx_prd_pic_001",
                "/p/hdk/cad/unquoted/2.0",
                "/p/hdk/cad/trailing/3.0",
            },
        )
        # bindings_design entries must not leak in
        self.assertNotIn("/p/gtkit/libs/tech/1.0", existing)

    def test_parse_existing_bindings_tools_no_section_returns_empty(self) -> None:
        self.assertEqual(cb.parse_existing_bindings_tools("defaults:\n  image: foo\n"), set())

    def test_filter_existing_in_yaml_drops_matches_and_keeps_new(self) -> None:
        existing = cb.parse_existing_bindings_tools(EXISTING_BINDINGS_YAML)
        entries = [
            cb.BindingEntry(directory="/p/hdk/cad/existing/1.0", flows=["vcs"]),
            cb.BindingEntry(directory="/nfs/site/disks/ipx_prd_pic_001", flows=["vcs"]),
            cb.BindingEntry(directory="/p/hdk/cad/trailing/3.0", flows=["vcs"]),
            cb.BindingEntry(directory="/p/hdk/cad/brand-new/9.0", flows=["vcs"]),
        ]
        kept, filtered = cb.filter_existing_in_yaml(entries, existing)
        self.assertEqual([e.directory for e in kept], ["/p/hdk/cad/brand-new/9.0"])
        self.assertEqual(len(filtered), 3)
        self.assertTrue(
            all(fe.reason == "already present in original yaml bindings_tools:" for fe in filtered)
        )


class TestActivityMappingParsing(unittest.TestCase):
    """Spec test 5 — activity mapping parsing."""

    def test_comments_and_blank_lines_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            mapping = Path(tmp) / "activity.map"
            mapping.write_text(
                "# comment\n\nvcssim verif\nvcs verif\n\n# trailing comment\n",
                encoding="utf-8",
            )
            entries = cb.parse_activity_mapping(mapping)
            self.assertEqual(
                [(e.flow, e.activity) for e in entries],
                [("vcssim", "verif"), ("vcs", "verif")],
            )

    def test_relative_mapping_path_resolved_against_workarea(self) -> None:
        workarea = Path("/nfs/site/disks/example/workarea")
        resolved = cb.resolve_activity_mapping_path("cfg/activity.map", workarea)
        self.assertEqual(resolved, workarea / "cfg" / "activity.map")

    def test_absolute_mapping_path_used_as_is(self) -> None:
        resolved = cb.resolve_activity_mapping_path("/abs/path/activity.map", Path("/workarea"))
        self.assertEqual(resolved, Path("/abs/path/activity.map"))


class TestFlowFailureHandling(unittest.TestCase):
    """Spec test 7 — flow failure handling."""

    def test_failed_flow_recorded_with_error_and_no_rows(self) -> None:
        def failing_runner(flow: str) -> subprocess.CompletedProcess:
            return subprocess.CompletedProcess(args=[], returncode=1, stdout="", stderr="boom")

        result = cb.process_flow("badflow", "verif", failing_runner)
        self.assertFalse(result.ok)
        self.assertEqual(result.error, "boom")
        self.assertEqual(result.rows, [])

    def test_successful_flow_parses_rows(self) -> None:
        def ok_runner(flow: str) -> subprocess.CompletedProcess:
            return subprocess.CompletedProcess(args=[], returncode=0, stdout=SAMPLE_QUERY_OUTPUT, stderr="")

        result = cb.process_flow("vcs", "verif", ok_runner)
        self.assertTrue(result.ok)
        self.assertIsNone(result.error)
        self.assertTrue(result.rows)


class TestReadableDirectoryFilter(unittest.TestCase):
    """Bug fix — only readable directories go into bindings_tools."""

    def test_partition_splits_real_dir_from_file_and_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            real_dir = Path(tmp) / "real_dir"
            real_dir.mkdir()
            real_file = Path(tmp) / "not_a_dir.spq"
            real_file.write_text("x", encoding="utf-8")
            missing = Path(tmp) / "does_not_exist"

            entries = [
                cb.BindingEntry(directory=str(real_dir), flows=["vcs"]),
                cb.BindingEntry(directory=str(real_file), flows=["vcs"]),
                cb.BindingEntry(directory=str(missing), flows=["vcs"]),
            ]
            accepted, missing_entries = cb.partition_readable(entries)
            self.assertEqual([e.directory for e in accepted], [str(real_dir)])
            self.assertEqual(
                {e.directory for e in missing_entries}, {str(real_file), str(missing)}
            )

    def test_unresolved_token_path_is_excluded(self) -> None:
        entries = [
            cb.BindingEntry(
                directory="/p/hdk/rtl/proj_tools/spyglass_methodology_cdc/master/toolversion(CDC_METHODOLOGY_VERSION)/",
                flows=["sgcdc"],
            )
        ]
        accepted, missing_entries = cb.partition_readable(entries)
        self.assertEqual(accepted, [])
        self.assertEqual(len(missing_entries), 1)


class TestVersionFloorReduction(unittest.TestCase):
    """Spec §4 — .new.reduced directory-tree reduction."""

    def test_digit_count_ignores_arrangement(self) -> None:
        self.assertEqual(cb.digit_count("X-2025.06-SP2-1"), 8)
        self.assertEqual(cb.digit_count("vcsmx"), 0)

    def test_known_version_values_filters_by_digit_count_and_section(self) -> None:
        rows = [
            cb.QueryRow(flow="vcs", section="TOOLVERSION", key="VCS_VERSION", value="X-2025.06-SP2-1"),
            cb.QueryRow(flow="vcs", section="TOOLVERSION", key="SHORT_VERSION", value="v1"),
            cb.QueryRow(flow="vcs", section="LITEINFRA", key="LITEINFRA_VERSION", value="2.301"),
            cb.QueryRow(flow="vcs", section="ENVS", key="VCS_HOME", value="/p/hdk/cad/vcsmx/X-2025.06-SP2-1"),
        ]
        versions = cb.known_version_values(rows)
        self.assertEqual(versions, {"X-2025.06-SP2-1", "2.301"})

    def test_version_floor_truncates_at_deepest_known_segment(self) -> None:
        known = {"X-2025.06-SP2-1"}
        self.assertEqual(
            cb.version_floor("/p/hdk/rtl/cad/synopsys/vc_static/X-2025.06-SP2-1/bin", known),
            "/p/hdk/rtl/cad/synopsys/vc_static/X-2025.06-SP2-1",
        )

    def test_version_floor_unchanged_without_match(self) -> None:
        self.assertEqual(cb.version_floor("/p/hdk/cad/foo/bar", set()), "/p/hdk/cad/foo/bar")

    def test_version_floor_never_goes_shallower_than_version_segment(self) -> None:
        # x86-64_linux26 must not be mistaken for the version segment.
        known = {"X-2025.06-SP2-1"}
        floor = cb.version_floor(
            "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vcsmx/X-2025.06-SP2-1/bin", known
        )
        self.assertEqual(floor, "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vcsmx/X-2025.06-SP2-1")

    def test_reduce_collapses_siblings_to_common_parent(self) -> None:
        known = {"26.05.6"}
        base = "/p/hdk/rtl/cad/x86-64_linux26/dt/OneSourceBundle/26.05.6"
        entries = [
            cb.BindingEntry(directory=f"{base}/OneSourceGen", flows=["crflow"]),
            cb.BindingEntry(directory=f"{base}/OneSourceXmlApi", flows=["crflow"]),
            cb.BindingEntry(directory=f"{base}/OneSourceIntegrator", flows=["fuseflow"]),
        ]
        groups = cb.reduce_bindings_additions(entries, known)
        self.assertEqual(len(groups), 1)
        self.assertEqual(groups[0].floor.directory, base)
        self.assertEqual(groups[0].floor.flows, ["crflow", "fuseflow"])
        self.assertEqual(len(groups[0].originals), 3)

    def test_reduce_collapses_parent_and_child(self) -> None:
        known = {"X-2025.06-SP2-1"}
        parent = "/p/hdk/rtl/cad/x86-64_linux26/synopsys/vc_static/X-2025.06-SP2-1"
        entries = [
            cb.BindingEntry(directory=parent, flows=["vcformal"]),
            cb.BindingEntry(directory=f"{parent}/bin", flows=["vcformal"]),
        ]
        groups = cb.reduce_bindings_additions(entries, known)
        self.assertEqual(len(groups), 1)
        self.assertEqual(groups[0].floor.directory, parent)

    def test_reduce_leaves_unrelated_entries_alone(self) -> None:
        known: set[str] = set()
        entries = [
            cb.BindingEntry(directory="/p/hdk/cad/foo/1.0", flows=["a"]),
            cb.BindingEntry(directory="/p/hdk/cad/bar/2.0", flows=["b"]),
        ]
        groups = cb.reduce_bindings_additions(entries, known)
        self.assertEqual([g.floor.directory for g in groups], [e.directory for e in entries])

    def test_reduce_merges_directories_differing_only_by_double_slash(self) -> None:
        known = {"X-2025.06-SP2"}
        entries = [
            cb.BindingEntry(directory="/p/hdk/cad/rtla//X-2025.06-SP2", flows=["rtla"]),
            cb.BindingEntry(directory="/p/hdk/cad/rtla/X-2025.06-SP2", flows=["rtla", "rtlaqor"]),
        ]
        groups = cb.reduce_bindings_additions(entries, known)
        self.assertEqual(len(groups), 1)
        self.assertEqual(groups[0].floor.directory, "/p/hdk/cad/rtla/X-2025.06-SP2")
        self.assertEqual(groups[0].floor.flows, ["rtla", "rtlaqor"])


class TestGenericDirectoryFilter(unittest.TestCase):
    """Post-reduction filter: drop existing/readable-but-too-generic directories."""

    def test_shallow_directory_removed_deeper_kept(self) -> None:
        self.assertTrue(cb.is_too_shallow("/p/hdk/cad/conformal"))
        self.assertFalse(cb.is_too_shallow("/p/hdk/cad/conformal/25.20-p100"))

    def test_eda_root_detection(self) -> None:
        self.assertTrue(cb.requires_version_basename("/p/hdk/cad/mint/v25ww40"))
        self.assertTrue(
            cb.requires_version_basename("/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer")
        )
        self.assertTrue(
            cb.requires_version_basename("/p/hdk/rtl/proj_tools/vc_methodology_lint/master")
        )
        self.assertFalse(cb.requires_version_basename("/nfs/site/proj/hdk/pu_tu/prd/liteinfra"))

    def test_version_like_basename(self) -> None:
        self.assertFalse(cb.has_version_like_basename("/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer"))
        self.assertTrue(
            cb.has_version_like_basename("/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer/w230217")
        )
        self.assertTrue(cb.has_version_like_basename("/p/hdk/cad/mint/v25ww40"))

    def test_version_like_basename_handles_trailing_slash(self) -> None:
        self.assertFalse(
            cb.has_version_like_basename("/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/")
        )
        self.assertTrue(
            cb.has_version_like_basename("/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/5.4")
        )

    def test_filter_generic_directories_worked_examples(self) -> None:
        entries = [
            cb.BindingEntry(directory="/p/hdk/cad/conformal", flows=["lec"]),
            cb.BindingEntry(directory="/p/hdk/cad/conformal/25.20-p100", flows=["lec"]),
            cb.BindingEntry(
                directory="/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer", flows=["mti"]
            ),
            cb.BindingEntry(
                directory="/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer/w230217", flows=["mti"]
            ),
            cb.BindingEntry(directory="/p/hdk/cad/mint/v25ww40", flows=["mint"]),
            cb.BindingEntry(
                directory="/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/", flows=["visa"]
            ),
            cb.BindingEntry(
                directory="/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/5.4", flows=["visa"]
            ),
            cb.BindingEntry(directory="/usr/intel/bin", flows=["vcs"]),
            cb.BindingEntry(directory="/p/hdk/pu_tu/prd", flows=["vcs"]),
            cb.BindingEntry(
                directory="/p/hdk/rtl/proj_tools/vc_methodology_lint/master", flows=["vc_lint"]
            ),
            cb.BindingEntry(
                directory="/p/hdk/rtl/proj_tools/vc_methodology_lint/master/2.02.23.25ww19",
                flows=["vc_lint"],
            ),
        ]
        kept, filtered = cb.filter_generic_directories(entries)
        kept_dirs = {e.directory for e in kept}
        filtered_dirs = {fe.entry.directory for fe in filtered}

        self.assertEqual(
            kept_dirs,
            {
                "/p/hdk/cad/conformal/25.20-p100",
                "/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer/w230217",
                "/p/hdk/cad/mint/v25ww40",
                "/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/5.4",
                "/p/hdk/rtl/proj_tools/vc_methodology_lint/master/2.02.23.25ww19",
            },
        )
        self.assertEqual(
            filtered_dirs,
            {
                "/p/hdk/cad/conformal",
                "/p/hdk/rtl/cad/x86-64_linux44/mentor/visualizer",
                "/p/hdk/rtl/cad/x86-64_linux26/intel/VisaIT/",
                "/usr/intel/bin",
                "/p/hdk/pu_tu/prd",
                "/p/hdk/rtl/proj_tools/vc_methodology_lint/master",
            },
        )


class TestUserFilterOption(unittest.TestCase):
    """--filter regex-file mechanism (applied after all other .new.reduced filtering)."""

    def test_parse_filter_file_ignores_comments_and_blanks(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            filt = Path(tmp) / "filter.txt"
            filt.write_text('# comment\n\n"foo"\n"bar.*baz"\n', encoding="utf-8")
            patterns = cb.parse_filter_file(filt)
            self.assertEqual([p.pattern for p in patterns], ["foo", "bar.*baz"])

    def test_parse_filter_file_allows_literal_slash_in_pattern(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            filt = Path(tmp) / "filter.txt"
            filt.write_text(r'"^\/p\/hdk\/rtl\/cad\/x86-64_linux26\/$"' + "\n", encoding="utf-8")
            patterns = cb.parse_filter_file(filt)
            self.assertTrue(patterns[0].search("/p/hdk/rtl/cad/x86-64_linux26/"))

    def test_parse_filter_file_rejects_malformed_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            filt = Path(tmp) / "filter.txt"
            filt.write_text("not-quote-delimited\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                cb.parse_filter_file(filt)

    def test_apply_user_filter_drops_matching_directories(self) -> None:
        patterns = [re.compile("vcsmx")]
        entries = [
            cb.BindingEntry(directory="/p/hdk/rtl/cad/x86-64_linux26/synopsys/vcsmx/1.0", flows=["vcs"]),
            cb.BindingEntry(directory="/p/hdk/rtl/cad/x86-64_linux26/synopsys/verdi3/1.0", flows=["vcs"]),
        ]
        kept, filtered = cb.apply_user_filter(entries, patterns)
        self.assertEqual([e.directory for e in kept], ["/p/hdk/rtl/cad/x86-64_linux26/synopsys/verdi3/1.0"])
        self.assertEqual(len(filtered), 1)
        self.assertIn('--filter pattern matched: "vcsmx"', filtered[0].reason)

    def test_apply_user_filter_no_patterns_is_noop(self) -> None:
        entries = [cb.BindingEntry(directory="/p/hdk/cad/foo/1.0", flows=["a"])]
        kept, filtered = cb.apply_user_filter(entries, [])
        self.assertEqual(kept, entries)
        self.assertEqual(filtered, [])


class TestIncludeOption(unittest.TestCase):
    """--include file mechanism (processed last, after reduction & all filtering)."""

    def test_parse_include_file_ignores_blanks_and_captures_no_comment(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            inc = Path(tmp) / "include.txt"
            inc.write_text("\n/a/b\n/a/c\n", encoding="utf-8")
            entries = cb.parse_include_file(inc)
            self.assertEqual(
                entries, [cb.IncludeEntry("/a/b", []), cb.IncludeEntry("/a/c", [])]
            )

    def test_parse_include_file_attaches_comment_to_next_directory_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            inc = Path(tmp) / "include.txt"
            inc.write_text(
                "# needed for nbfeeder\n/a/b\n/a/c\n# second note\n/a/d\n", encoding="utf-8"
            )
            entries = cb.parse_include_file(inc)
            self.assertEqual(
                entries,
                [
                    cb.IncludeEntry("/a/b", ["needed for nbfeeder"]),
                    cb.IncludeEntry("/a/c", []),
                    cb.IncludeEntry("/a/d", ["second note"]),
                ],
            )

    def test_parse_include_file_comments_accumulate_across_blank_lines(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            inc = Path(tmp) / "include.txt"
            inc.write_text("# header\n\n# more context\n/a/b\n", encoding="utf-8")
            entries = cb.parse_include_file(inc)
            self.assertEqual(entries, [cb.IncludeEntry("/a/b", ["header", "more context"])])

    def test_add_includes_appends_new_directory_tagged_include(self) -> None:
        entries = [cb.BindingEntry(directory="/p/hdk/cad/foo/1.0", flows=["a"])]
        include_entries = [
            cb.IncludeEntry("/nfs/site/gen/adm/netbatch/install/2.5.4", ["needed for nbfeeder"])
        ]
        combined, results = cb.add_includes(entries, include_entries)
        self.assertEqual(len(combined), 2)
        self.assertEqual(combined[1].directory, "/nfs/site/gen/adm/netbatch/install/2.5.4")
        self.assertEqual(combined[1].flows, ["--include"])
        self.assertEqual(combined[1].comments, ["needed for nbfeeder"])
        self.assertEqual(results, [cb.IncludeResult(directory="/nfs/site/gen/adm/netbatch/install/2.5.4", added=True)])

    def test_add_includes_skips_duplicate_of_existing_entry(self) -> None:
        entries = [cb.BindingEntry(directory="/p/hdk/cad/foo/1.0", flows=["a"])]
        combined, results = cb.add_includes(entries, [cb.IncludeEntry("/p/hdk/cad/foo/1.0", [])])
        self.assertEqual(len(combined), 1)
        self.assertEqual(results, [cb.IncludeResult(directory="/p/hdk/cad/foo/1.0", added=False)])

    def test_add_includes_dedups_duplicate_lines_within_include_file(self) -> None:
        combined, results = cb.add_includes(
            [], [cb.IncludeEntry("/a/b", []), cb.IncludeEntry("/a/b", ["ignored"])]
        )
        self.assertEqual(len(combined), 1)
        self.assertEqual(len(results), 1)

    def test_render_addition_block_includes_carried_over_comment(self) -> None:
        entries = [
            cb.BindingEntry(
                directory="/nfs/site/gen/adm/netbatch/install/2.5.4",
                flows=["--include"],
                comments=["needed for nbfeeder"],
            )
        ]
        lines = cb.render_addition_block(entries)
        self.assertEqual(
            lines,
            [
                "  # Start cthbind additions",
                "  # Registered by flows: --include",
                "  # needed for nbfeeder",
                '  - "/nfs/site/gen/adm/netbatch/install/2.5.4"',
                "  # Finish cthbind additions",
            ],
        )

    def test_render_include_section_shows_status_per_directory(self) -> None:
        results = [
            cb.IncludeResult(directory="/a/added", added=True),
            cb.IncludeResult(directory="/a/skipped", added=False),
        ]
        lines = cb.render_include_section(results)
        text = "\n".join(lines)
        self.assertIn("# Summary of directories added via --include", text)
        self.assertIn("# Status: added", text)
        self.assertIn("/a/added", text)
        self.assertIn("# Status: skipped (already present in .final)", text)
        self.assertIn("/a/skipped", text)
        # file order preserved
        self.assertLess(text.index("/a/added"), text.index("/a/skipped"))


class TestReportRendering(unittest.TestCase):
    """Spec §4 — .cthbind.report sections."""

    def test_missing_directories_section_sorted_with_flow_comment(self) -> None:
        missing = [
            cb.BindingEntry(directory="/z/missing", flows=["vcs"]),
            cb.BindingEntry(directory="/a/missing", flows=["vcssim", "vcs"]),
        ]
        lines = cb.render_missing_directories_section(missing)
        self.assertEqual(lines[0], "# Summary of missing directories")
        self.assertIn("# Registered by flows: vcssim vcs", lines)
        # sorted alphabetically: /a/missing before /z/missing
        self.assertLess(lines.index("/a/missing"), lines.index("/z/missing"))

    def test_duplicate_toolversions_section_reports_only_keys_with_multiple_values(self) -> None:
        rows = [
            cb.QueryRow(flow="vcs", section="TOOLVERSION", key="VCS_VERSION", value="X-2025.06-SP2"),
            cb.QueryRow(flow="vcssim", section="TOOLVERSION", key="VCS_VERSION", value="X-2024.09-SP1"),
            cb.QueryRow(flow="vcs", section="TOOLVERSION", key="XLM_VERSION", value="25.03.004"),
            cb.QueryRow(flow="vcssim", section="TOOLVERSION", key="XLM_VERSION", value="25.03.004"),
        ]
        lines = cb.render_duplicate_toolversions_section(rows)
        text = "\n".join(lines)
        self.assertIn("Total unique keys with at least one duplicate value: 1", text)
        self.assertIn("VCS_VERSION\tTotal Unique Values: 2", text)
        self.assertNotIn("XLM_VERSION\tTotal Unique Values", text)
        self.assertIn("VCS_VERSION=X-2025.06-SP2", text)
        self.assertIn("VCS_VERSION=X-2024.09-SP1", text)

    def test_reduction_summary_only_lists_changed_groups(self) -> None:
        known = {"1.0"}
        unchanged = cb.reduce_bindings_additions(
            [cb.BindingEntry(directory="/p/hdk/cad/foo/1.0", flows=["a"])], known
        )
        changed = cb.reduce_bindings_additions(
            [
                cb.BindingEntry(directory="/p/hdk/cad/bar/1.0", flows=["a"]),
                cb.BindingEntry(directory="/p/hdk/cad/bar/1.0/bin", flows=["b"]),
            ],
            known,
        )
        lines = cb.render_reduction_summary_section(unchanged + changed)
        text = "\n".join(lines)
        self.assertNotIn("/p/hdk/cad/foo/1.0", text)
        self.assertIn("Group Before reduction:", text)
        self.assertIn("/p/hdk/cad/bar/1.0/bin", text)

    def test_generic_filter_section_lists_reason_and_flows(self) -> None:
        filtered = [
            cb.FilteredEntry(
                entry=cb.BindingEntry(directory="/usr/intel/bin", flows=["vcs"]),
                reason="too shallow (<=4 levels deep)",
            )
        ]
        lines = cb.render_generic_filter_section(filtered)
        text = "\n".join(lines)
        self.assertIn("# Summary of directories filtered from .final", text)
        self.assertIn("# Registered by flows: vcs", text)
        self.assertIn("# Reason: too shallow (<=4 levels deep)", text)
        self.assertIn("/usr/intel/bin", text)

    def test_counts_section_lists_all_metrics_and_path(self) -> None:
        counts = cb.RunCounts(
            found=10,
            found_readable=8,
            grouped=6,
            after_filtering=5,
            include_total=2,
            include_readable=2,
            final_total=7,
            final_path=Path("/tmp/x.yml.cthbind.final"),
        )
        lines = cb.render_counts_section(counts)
        text = "\n".join(lines)
        self.assertEqual(lines[0], "# Summary of counts")
        self.assertIn("Total directories found in cth_query registry (deduplicated): 10", text)
        self.assertIn("Total readable directories found in cth_query registry: 8", text)
        self.assertIn("Total readable directories after grouping: 6", text)
        self.assertIn("Total readable directories after filtering: 5", text)
        self.assertIn("Total directories provided in --includes: 2", text)
        self.assertIn("Total readable directories provided in --includes: 2", text)
        self.assertIn("Final bindings added to output yaml: 7", text)
        self.assertIn("Output yaml: /tmp/x.yml.cthbind.final", text)

    def test_build_report_includes_all_six_sections(self) -> None:
        counts = cb.RunCounts(
            found=0,
            found_readable=0,
            grouped=0,
            after_filtering=0,
            include_total=0,
            include_readable=0,
            final_total=0,
            final_path=Path("/tmp/x.yml.cthbind.final"),
        )
        report = cb.build_report(
            counts=counts,
            missing=[],
            all_rows=[],
            reduction_groups=[],
            filtered_generic=[],
            include_results=[],
        )
        self.assertIn("# Summary of counts", report)
        self.assertIn("# Summary of missing directories", report)
        self.assertIn("# Summary of duplicate toolversions", report)
        self.assertIn("# Summary of directory reductions for .final file", report)
        self.assertIn("# Summary of directories filtered from .final", report)
        self.assertIn("# Summary of directories added via --include", report)
        # counts section must be first
        self.assertTrue(report.startswith("# Summary of counts"))


class TestIncrementalLog(unittest.TestCase):
    """Spec §4 — .log is written incrementally (header, then per-flow appends)."""

    def test_header_then_flow_blocks_appended_in_order(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            log_path = Path(tmp) / "out.log"
            cb.write_log_header(log_path, "cthbind.py --input-yaml x.yml", 1_700_000_000.0, 0)
            header_only = log_path.read_text(encoding="utf-8")
            self.assertIn("Command: cthbind.py", header_only)

            ok_fr = cb.FlowResult("vcs", "verif", True, None, SAMPLE_QUERY_OUTPUT, cb.rows_for_flow("vcs", SAMPLE_QUERY_OUTPUT))
            cb.append_log_flow(log_path, ok_fr, 0)
            failed_fr = cb.FlowResult("badflow", "verif", False, "boom", "", [])
            cb.append_log_flow(log_path, failed_fr, 0)

            full_text = log_path.read_text(encoding="utf-8")
            self.assertLess(full_text.index("Flow: vcs"), full_text.index("Flow: badflow"))
            self.assertIn("-E- cth_query failed: boom", full_text)


class TestGlobalCthQueryCall(unittest.TestCase):
    """No-args `cth_query -resolve` call, run once (not tied to any flow)."""

    def test_global_runner_invokes_cth_query_without_tool_flag(self) -> None:
        captured: dict[str, list[str]] = {}

        def fake_run(cmd, **kwargs):  # noqa: ANN001
            captured["cmd"] = cmd
            return subprocess.CompletedProcess(cmd, 0, SAMPLE_QUERY_OUTPUT, "")

        import unittest.mock as mock

        with mock.patch.object(subprocess, "run", fake_run):
            proc = cb.default_global_cth_query_runner("unused")
        self.assertEqual(captured["cmd"], ["cth_query", "-resolve"])
        self.assertEqual(proc.stdout, SAMPLE_QUERY_OUTPUT)

    def test_global_call_processed_like_a_flow_result(self) -> None:
        def ok_runner(flow: str) -> subprocess.CompletedProcess:
            return subprocess.CompletedProcess(args=[], returncode=0, stdout=SAMPLE_QUERY_OUTPUT, stderr="")

        result = cb.process_flow(cb.GLOBAL_FLOW, cb.GLOBAL_ACTIVITY, ok_runner)
        self.assertTrue(result.ok)
        self.assertEqual(result.flow, "GLOBAL")
        self.assertTrue(result.rows)
        # rows carry the GLOBAL flow label, so they flow into bindings_tools/CSV like any other flow
        self.assertTrue(all(row.flow == "GLOBAL" for row in result.rows))


if __name__ == "__main__":
    unittest.main()
