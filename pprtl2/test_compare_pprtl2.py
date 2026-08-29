#!/usr/bin/env python3
"""Unit tests for compare_pprtl2 (see compare_pprtl2.spec.md §7 test plan).

Covers test-plan items 1-7: TestReadModelsFile, TestPreflight,
TestMetricDerivation, TestNumericBacking, TestPercentDiff, TestBuildTable,
TestGenerateReports, plus the CLI wiring they feed (TestCli).

Run:  python3 -m unittest test_compare_pprtl2 -v
  or: python3 test_compare_pprtl2.py
"""

from __future__ import annotations

import contextlib
import csv
import io
import tempfile
import unittest
from pathlib import Path

import compare_pprtl2 as cp

COMPUTE_HEADER = (
    "module,power_mode,test_name,instance,elab_run_status,fsdb_run_status,power_run_status,"
    "cell_count,elab_runtime,elab_runtime_seconds,fsdb_runtime,fsdb_runtime_seconds,"
    "power_runtime,power_runtime_seconds,total_runtime,total_runtime_seconds,"
    "elab_peak_memory,fsdb_peak_memory,power_peak_memory"
)

QOR_HEADER = (
    "module,power_mode,test_name,instance,elab_run_status,fsdb_run_status,power_run_status,"
    "untraced_sequentials_percentage,annotation_primary_io,annotation_bb,annotation_seq,"
    "CGR,CGE,DACGE,"
    "cell_count,combinational_cell_count,unclocked_sequential_cell_count,"
    "register_cell_count,register_bit_count,"
    "flop_cell_count,mbflop_cell_count,eqfb,latch_cell_count,mblatch_cell_count,eqlb,"
    "VCS_VERSION,VERDI_VERSION,PPRTL_VERSION"
)

COMPUTE_ROW = (
    "paraccasf,vectorless,default,,Pass,Not Required,Pass,95549,00d:00h:32m:14s,1934.0,,,"
    "00d:00h:03m:53s,233.0,00d:00h:36m:07s,2167.0,12.63 GB,,8.77 GB"
)

QOR_ROW = (
    "paraccasf,vectorless,default,,Pass,Not Required,Pass,8.45,,,,99.37,97.31,97.85,"
    "95549,76690,1266,13709,80044,3073,10447,79359,23,166,685,"
    "X-2025.06-SP2-3,X-2025.06-SP2,X-2025.06-SP3-20260214"
)

COMPUTE_COLUMNS = COMPUTE_HEADER.split(",")
QOR_COLUMNS = QOR_HEADER.split(",")
COMPUTE_DEFAULTS = dict(zip(COMPUTE_COLUMNS, COMPUTE_ROW.split(",")))
QOR_DEFAULTS = dict(zip(QOR_COLUMNS, QOR_ROW.split(",")))


def compute_row(**overrides: str) -> str:
    """One report_pprtl2.compute.csv data line, with any column overridden."""
    values = {**COMPUTE_DEFAULTS, **overrides}
    return ",".join(values[c] for c in COMPUTE_COLUMNS)


def qor_row(**overrides: str) -> str:
    """One report_pprtl2.qor.csv data line, with any column overridden."""
    values = {**QOR_DEFAULTS, **overrides}
    return ",".join(values[c] for c in QOR_COLUMNS)


def compute_with(*extra_rows: str, **overrides: str) -> str:
    rows = [compute_row(**overrides), *extra_rows]
    return COMPUTE_HEADER + "\n" + "\n".join(rows) + "\n"


def qor_with(*extra_rows: str, **overrides: str) -> str:
    rows = [qor_row(**overrides), *extra_rows]
    return QOR_HEADER + "\n" + "\n".join(rows) + "\n"


def make_workarea(root: Path, name: str, *, compute: str | None = None, qor: str | None = None) -> Path:
    """Create <root>/<name>/power/pprtl2/report_pprtl2.{compute,qor}.csv."""
    workarea = root / name
    reports = workarea / "power" / "pprtl2"
    reports.mkdir(parents=True, exist_ok=True)
    if compute is not None:
        (reports / "report_pprtl2.compute.csv").write_text(compute, encoding="utf-8")
    if qor is not None:
        (reports / "report_pprtl2.qor.csv").write_text(qor, encoding="utf-8")
    return workarea


def default_compute() -> str:
    return compute_with()


def default_qor() -> str:
    return qor_with()


class TestReadModelsFile(unittest.TestCase):
    """Spec §7 item 1 -- S1 parsing (§2.2)."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def _write(self, text: str) -> Path:
        path = self.root / "models.md"
        path.write_text(text, encoding="utf-8")
        return path

    def test_parses_pairs_in_order_skipping_comments_and_blanks(self) -> None:
        path = self._write(
            "# compare_pprtl2 input model list\n"
            "# format is <model>=<workarea>\n"
            "\n"
            "26ww27a=/wa/b\n"
            "26ww32d=/wa/c\n"
        )
        entries = cp.read_models_file(path)
        self.assertEqual([e.name for e in entries], ["26ww27a", "26ww32d"])
        self.assertEqual([e.workarea for e in entries], [Path("/wa/b"), Path("/wa/c")])

    def test_tolerates_whitespace_and_ignores_trailing_text(self) -> None:
        path = self._write("  m1  =  /wa/one   some trailing note\nm2=/wa/two\n")
        entries = cp.read_models_file(path)
        self.assertEqual(entries[0].name, "m1")
        self.assertEqual(entries[0].workarea, Path("/wa/one"))
        self.assertEqual(entries[1].workarea, Path("/wa/two"))

    def test_report_csv_paths_are_derived_from_the_workarea(self) -> None:
        path = self._write("m1=/wa/one\nm2=/wa/two\n")
        first = cp.read_models_file(path)[0]
        self.assertEqual(first.compute_csv, Path("/wa/one/power/pprtl2/report_pprtl2.compute.csv"))
        self.assertEqual(first.qor_csv, Path("/wa/one/power/pprtl2/report_pprtl2.qor.csv"))

    def test_malformed_line_is_an_error(self) -> None:
        path = self._write("m1=/wa/one\nthis line has no equals sign\nm2=/wa/two\n")
        with self.assertRaises(ValueError) as ctx:
            cp.read_models_file(path)
        self.assertIn(":2:", str(ctx.exception))

    def test_fewer_than_two_models_is_an_error(self) -> None:
        path = self._write("# only one\nm1=/wa/one\n")
        with self.assertRaises(ValueError) as ctx:
            cp.read_models_file(path)
        self.assertIn("at least 2", str(ctx.exception))

    def test_duplicate_model_name_is_an_error(self) -> None:
        path = self._write("m1=/wa/one\nm1=/wa/two\n")
        with self.assertRaises(ValueError) as ctx:
            cp.read_models_file(path)
        self.assertIn("duplicate model name", str(ctx.exception))

    def test_comma_in_model_name_is_an_error(self) -> None:
        path = self._write("m,1=/wa/one\nm2=/wa/two\n")
        with self.assertRaises(ValueError) as ctx:
            cp.read_models_file(path)
        self.assertIn("may not contain", str(ctx.exception))

    def test_missing_models_file_is_an_error(self) -> None:
        with self.assertRaises(ValueError):
            cp.read_models_file(self.root / "nope.md")


class TestPreflight(unittest.TestCase):
    """Spec §7 item 2 -- every §2.1 failure mode, plus the happy path."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.outdir = self.root / "out"
        self.outdir.mkdir()

    def _cfg(self, *workareas: Path, outdir: Path | None = None) -> cp.Config:
        models = tuple(
            cp.ModelEntry(name=f"m{i}", workarea=wa) for i, wa in enumerate(workareas, 1)
        )
        return cp.Config(models=models, outdir=outdir if outdir is not None else self.outdir)

    def test_clean_inputs_produce_no_errors(self) -> None:
        wa1 = make_workarea(self.root, "wa1", compute=default_compute(), qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        self.assertEqual(cp.preflight(self._cfg(wa1, wa2)), [])

    def test_missing_outdir_is_an_error(self) -> None:
        wa1 = make_workarea(self.root, "wa1", compute=default_compute(), qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        errors = cp.preflight(self._cfg(wa1, wa2, outdir=self.root / "missing"))
        self.assertTrue(any("--outdir does not exist" in e for e in errors))

    def test_missing_workarea_is_an_error(self) -> None:
        wa1 = make_workarea(self.root, "wa1", compute=default_compute(), qor=default_qor())
        errors = cp.preflight(self._cfg(wa1, self.root / "nope"))
        self.assertEqual(len(errors), 1)
        self.assertIn("workarea not found", errors[0])

    def test_missing_compute_csv_is_an_error(self) -> None:
        wa1 = make_workarea(self.root, "wa1", qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        errors = cp.preflight(self._cfg(wa1, wa2))
        self.assertEqual(len(errors), 1)
        self.assertIn("report_pprtl2.compute.csv", errors[0])

    def test_missing_qor_csv_is_an_error(self) -> None:
        wa1 = make_workarea(self.root, "wa1", compute=default_compute())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        errors = cp.preflight(self._cfg(wa1, wa2))
        self.assertEqual(len(errors), 1)
        self.assertIn("report_pprtl2.qor.csv", errors[0])

    def test_header_missing_a_key_column_is_an_error(self) -> None:
        bad = "module,power_mode,test_name,cell_count\nparaccasf,vectorless,default,95549\n"
        wa1 = make_workarea(self.root, "wa1", compute=bad, qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        errors = cp.preflight(self._cfg(wa1, wa2))
        self.assertEqual(len(errors), 1)
        self.assertIn("missing key column(s): instance", errors[0])

    def test_duplicate_compare_key_is_an_error(self) -> None:
        dup = compute_with(compute_row())
        wa1 = make_workarea(self.root, "wa1", compute=dup, qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        errors = cp.preflight(self._cfg(wa1, wa2))
        self.assertEqual(len(errors), 1)
        self.assertIn("duplicate compare key: paraccasf,vectorless,default,", errors[0])

    def test_same_test_name_with_distinct_instances_is_not_a_duplicate(self) -> None:
        # Real data (verified): timebased runs put several instances under one
        # test name -- this is exactly why `instance` is part of the key.
        timebased = dict(
            module="parscfllcsftype3", power_mode="timebased", test_name="active_idle",
        )
        two_instances = compute_with(
            compute_row(**timebased, instance="parllcsf_a_parscfllcsftype4"),
            **timebased, instance="parllcsf_a_parscfllcsftype3",
        )
        wa1 = make_workarea(self.root, "wa1", compute=two_instances, qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        self.assertEqual(cp.preflight(self._cfg(wa1, wa2)), [])

    def test_comment_lines_in_source_csv_are_skipped(self) -> None:
        commented = COMPUTE_HEADER + "\n# a comment row\n" + compute_row() + "\n"
        wa1 = make_workarea(self.root, "wa1", compute=commented, qor=default_qor())
        wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        self.assertEqual(cp.preflight(self._cfg(wa1, wa2)), [])


class TestRowKey(unittest.TestCase):
    """Spec §2.3 test_name normalization (also exercised via preflight)."""

    def test_blank_vectorless_test_name_becomes_default(self) -> None:
        row = {"module": "m", "power_mode": "vectorless", "test_name": "", "instance": ""}
        self.assertEqual(cp.row_key(row), ("m", "vectorless", "default", ""))

    def test_blank_timebased_test_name_stays_blank(self) -> None:
        row = {"module": "m", "power_mode": "timebased", "test_name": "", "instance": ""}
        self.assertEqual(cp.row_key(row), ("m", "timebased", "", ""))

    def test_values_are_stripped(self) -> None:
        row = {"module": " m ", "power_mode": "timebased", "test_name": " t ", "instance": " i "}
        self.assertEqual(cp.row_key(row), ("m", "timebased", "t", "i"))


class TestMetricDerivation(unittest.TestCase):
    """Spec §7 item 3 -- §3.1/§3.2/§3.3 metric columns, derived not hardcoded."""

    def test_qor_metrics_match_the_spec_list(self) -> None:
        metrics = cp.derive_metrics(cp.QOR, [QOR_HEADER.split(",")])
        self.assertEqual(metrics, [
            "untraced_sequentials_percentage", "annotation_primary_io",
            "annotation_bb", "annotation_seq",
            "CGR", "CGE", "DACGE",
            "cell_count", "combinational_cell_count", "unclocked_sequential_cell_count",
            "register_cell_count", "register_bit_count",
            "flop_cell_count", "mbflop_cell_count", "eqfb",
            "latch_cell_count", "mblatch_cell_count", "eqlb",
        ])

    def test_compute_metrics_match_the_spec_list(self) -> None:
        metrics = cp.derive_metrics(cp.COMPUTE, [COMPUTE_HEADER.split(",")])
        self.assertEqual(metrics, [
            "cell_count",
            "elab_runtime", "fsdb_runtime", "power_runtime", "total_runtime",
            "elab_peak_memory", "fsdb_peak_memory", "power_peak_memory",
        ])

    def test_columns_unique_to_one_model_are_appended_in_first_seen_order(self) -> None:
        metrics = cp.derive_metrics(cp.QOR, [
            ["module", "power_mode", "test_name", "instance", "CGR"],
            ["module", "power_mode", "test_name", "instance", "CGR", "brand_new_metric"],
        ])
        self.assertEqual(metrics, ["CGR", "brand_new_metric"])

    def test_a_new_source_column_becomes_a_metric_without_a_code_change(self) -> None:
        metrics = cp.derive_metrics(cp.COMPUTE, [COMPUTE_HEADER.split(",") + ["future_column"]])
        self.assertIn("future_column", metrics)


class TestNumericBacking(unittest.TestCase):
    """Spec §7 item 4 -- §3.4 display value vs. numeric backing value."""

    def test_plain_numeric_uses_its_own_value(self) -> None:
        self.assertEqual(cp.backing_value("CGR", {"CGR": "97.35"}), 97.35)

    def test_runtime_uses_the_seconds_column(self) -> None:
        row = {"elab_runtime": "00d:00h:32m:14s", "elab_runtime_seconds": "1934.0"}
        self.assertEqual(cp.backing_value("elab_runtime", row), 1934.0)

    def test_runtime_without_a_seconds_column_is_non_numeric(self) -> None:
        self.assertIsNone(cp.backing_value("elab_runtime", {"elab_runtime": "00d:00h:32m:14s"}))

    def test_memory_units_scale_by_decimal_factors(self) -> None:
        self.assertEqual(cp.parse_memory("12.63 GB"), 12.63e9)
        self.assertEqual(cp.parse_memory("500 MB"), 500e6)
        self.assertEqual(cp.parse_memory("1024KB"), 1024e3)
        self.assertEqual(cp.parse_memory("2 TB"), 2e12)
        self.assertEqual(cp.parse_memory("8 B"), 8.0)

    def test_memory_comparison_across_units_is_consistent(self) -> None:
        self.assertEqual(cp.parse_memory("1 GB"), cp.parse_memory("1000 MB"))

    def test_unparseable_or_blank_values_are_non_numeric(self) -> None:
        self.assertIsNone(cp.parse_memory("12.63 gigabytes"))
        self.assertIsNone(cp.parse_memory(""))
        self.assertIsNone(cp.backing_value("elab_peak_memory", {"elab_peak_memory": "n/a"}))
        self.assertIsNone(cp.backing_value("CGR", {"CGR": ""}))
        self.assertIsNone(cp.backing_value("CGR", {}))

    def test_missing_row_is_non_numeric(self) -> None:
        self.assertIsNone(cp.backing_value("CGR", None))


class TestPercentDiff(unittest.TestCase):
    """Spec §7 item 5 -- §3.1 % diff rules and blank-cell cases."""

    def test_increase_decrease_and_no_change(self) -> None:
        self.assertEqual(cp.percent_diff(95549.0, 96000.0), "0.47")
        self.assertEqual(cp.percent_diff(97.35, 96.10), "-1.28")
        self.assertEqual(cp.percent_diff(81.42, 81.42), "0.00")

    def test_rounds_to_two_decimals(self) -> None:
        self.assertEqual(cp.percent_diff(3.0, 4.0), "33.33")

    def test_missing_or_non_numeric_sides_are_blank(self) -> None:
        self.assertEqual(cp.percent_diff(None, 5.0), "")
        self.assertEqual(cp.percent_diff(5.0, None), "")

    def test_zero_baseline_is_blank_not_a_division_error(self) -> None:
        self.assertEqual(cp.percent_diff(0.0, 5.0), "")


class _TableCase(unittest.TestCase):
    """Shared fixture for the table-building tests."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def _cfg(self, *specs: tuple[str, str, str]) -> cp.Config:
        """specs: (model name, compute csv text, qor csv text)."""
        models = []
        for name, compute, qor in specs:
            workarea = make_workarea(self.root, name, compute=compute, qor=qor)
            models.append(cp.ModelEntry(name=name, workarea=workarea))
        return cp.Config(models=tuple(models), outdir=self.root)

    @staticmethod
    def _metric_row(table: cp.CompareTable, metric: str, module: str | None = None) -> list[str]:
        for row in table.rows:
            if row[4] == metric and (module is None or row[0] == module):
                return row
        raise AssertionError(f"metric row not found: {metric}")


class TestBuildTable(_TableCase):
    """Spec §7 item 6 -- union key coverage, sort order, baseline-only diffs."""

    def test_header_has_the_baseline_block_then_the_chained_block(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), default_qor()),
            ("m3", default_compute(), default_qor()),
        )
        self.assertEqual(cp.build_table(cfg, cp.QOR).header, [
            "module", "power_mode", "test_name", "instance", "metric",
            "m1", "m2", "m3",
            "m2 vs m1 % diff", "m3 vs m1 % diff",
            "m3 vs m2 % diff",
        ])

    def test_two_models_get_no_chained_column(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), default_qor()),
        )
        self.assertEqual(cp.build_table(cfg, cp.QOR).header, [
            "module", "power_mode", "test_name", "instance", "metric",
            "m1", "m2", "m2 vs m1 % diff",
        ])

    def test_baseline_columns_use_the_baseline_and_chained_use_the_neighbour(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), qor_with(CGR="100")),
            ("m2", default_compute(), qor_with(CGR="200")),
            ("m3", default_compute(), qor_with(CGR="400")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "CGR")
        self.assertEqual(row[5:], ["100", "200", "400", "100.00", "300.00", "100.00"])

    def test_chain_order_follows_the_models_file_order(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), qor_with(CGR="100")),
            ("m2", default_compute(), qor_with(CGR="50")),
            ("m3", default_compute(), qor_with(CGR="100")),
            ("m4", default_compute(), qor_with(CGR="200")),
        )
        table = cp.build_table(cfg, cp.QOR)
        self.assertEqual(table.header[9:], [
            "m2 vs m1 % diff", "m3 vs m1 % diff", "m4 vs m1 % diff",
            "m3 vs m2 % diff", "m4 vs m3 % diff",
        ])
        row = self._metric_row(table, "CGR")
        self.assertEqual(row[9:], ["-50.00", "0.00", "100.00", "100.00", "100.00"])

    def test_values_are_verbatim_and_diffs_use_the_backing_values(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", compute_with(
                elab_runtime="00d:00h:35m:00s", elab_runtime_seconds="2100.0",
                elab_peak_memory="13.10 GB",
            ), default_qor()),
        )
        table = cp.build_table(cfg, cp.COMPUTE)
        runtime = self._metric_row(table, "elab_runtime")
        self.assertEqual(runtime[5:], ["00d:00h:32m:14s", "00d:00h:35m:00s", "8.58"])
        memory = self._metric_row(table, "elab_peak_memory")
        self.assertEqual(memory[5:], ["12.63 GB", "13.10 GB", "3.72"])

    def test_blank_source_value_yields_blank_value_and_blank_diff(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", compute_with(cell_count=""), default_qor()),
        )
        row = self._metric_row(cp.build_table(cfg, cp.COMPUTE), "cell_count")
        self.assertEqual(row[5:], ["95549", "", ""])

    def test_key_missing_from_the_baseline_still_produces_rows(self) -> None:
        extra = compute_with(compute_row(module="newpartition", cell_count="42"))
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", extra, default_qor()),
        )
        table = cp.build_table(cfg, cp.COMPUTE)
        self.assertIn(("newpartition", "vectorless", "default", ""), table.keys)
        row = self._metric_row(table, "cell_count", module="newpartition")
        self.assertEqual(row[5:], ["", "42", ""])

    def test_column_missing_from_one_model_is_blank_there(self) -> None:
        trimmed_header = ",".join(c for c in QOR_HEADER.split(",") if c != "CGE")
        trimmed_row = ",".join(
            v for c, v in zip(QOR_HEADER.split(","), QOR_ROW.split(",")) if c != "CGE"
        )
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), trimmed_header + "\n" + trimmed_row + "\n"),
        )
        table = cp.build_table(cfg, cp.QOR)
        self.assertIn("CGE", table.metrics)
        self.assertEqual(self._metric_row(table, "CGE")[5:], ["97.31", "", ""])

    def test_rows_are_sorted_by_key_with_each_key_s_metrics_adjacent(self) -> None:
        two_keys = compute_with(compute_row(
            module="aaa", power_mode="timebased", test_name="active_idle", instance="aaa_aaa",
        ))
        cfg = self._cfg(
            ("m1", two_keys, default_qor()),
            ("m2", two_keys, default_qor()),
        )
        table = cp.build_table(cfg, cp.COMPUTE)
        self.assertEqual(table.keys, [
            ("aaa", "timebased", "active_idle", "aaa_aaa"),
            ("paraccasf", "vectorless", "default", ""),
        ])
        self.assertEqual(len(table.rows), len(table.keys) * len(table.metrics))
        self.assertEqual([r[0] for r in table.rows[:len(table.metrics)]], ["aaa"] * len(table.metrics))
        self.assertEqual([r[4] for r in table.rows[:len(table.metrics)]], table.metrics)

    def test_vectorless_blank_test_name_merges_with_default_across_models(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", compute_with(test_name=""), default_qor()),
        )
        table = cp.build_table(cfg, cp.COMPUTE)
        self.assertEqual(table.keys, [("paraccasf", "vectorless", "default", "")])
        self.assertEqual(self._metric_row(table, "cell_count")[5:], ["95549", "95549", "0.00"])

    def test_timebased_blank_test_name_stays_a_distinct_key(self) -> None:
        timebased_blank = compute_with(compute_row(
            module="parmiopcie6trcore_uio_0", power_mode="timebased", test_name="", instance="",
        ))
        cfg = self._cfg(
            ("m1", timebased_blank, default_qor()),
            ("m2", timebased_blank, default_qor()),
        )
        table = cp.build_table(cfg, cp.COMPUTE)
        self.assertIn(("parmiopcie6trcore_uio_0", "timebased", "", ""), table.keys)


class TestStatusLabel(unittest.TestCase):
    """Spec §7 item 8 -- power_run_status -> value-column label (§3.5)."""

    def test_pass_and_missing_rows_have_no_label(self) -> None:
        self.assertEqual(cp.status_label({"power_run_status": "Pass"}), "")
        self.assertEqual(cp.status_label({"power_run_status": ""}), "")
        self.assertEqual(cp.status_label({}), "")
        self.assertEqual(cp.status_label(None), "")

    def test_exit_code_is_stripped_from_fail(self) -> None:
        self.assertEqual(cp.status_label({"power_run_status": "Fail=2"}), "Fail")
        self.assertEqual(cp.status_label({"power_run_status": "Fail=139"}), "Fail")

    def test_other_non_passing_statuses_pass_through_verbatim(self) -> None:
        self.assertEqual(cp.status_label({"power_run_status": "Not Started"}), "Not Started")
        self.assertEqual(cp.status_label({"power_run_status": " Running "}), "Running")

    def test_elab_and_fsdb_statuses_are_ignored(self) -> None:
        row = {
            "elab_run_status": "Fail=2",
            "fsdb_run_status": "Fail=2",
            "power_run_status": "Pass",
        }
        self.assertEqual(cp.status_label(row), "")


class TestFailedRunSubstitution(_TableCase):
    """Spec §7 item 8 -- non-passing power runs report status, never numbers."""

    def test_failed_model_shows_fail_in_its_value_column_with_no_diff(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(power_run_status="Fail=2")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "CGR")
        self.assertEqual(row[5:], ["99.37", "Fail", ""])

    def test_bogus_zeros_from_a_failed_run_are_replaced(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(
                power_run_status="Fail=2", CGR="0", register_cell_count="0",
            )),
        )
        table = cp.build_table(cfg, cp.QOR)
        self.assertEqual(self._metric_row(table, "CGR")[5:], ["99.37", "Fail", ""])
        self.assertEqual(
            self._metric_row(table, "register_cell_count")[5:], ["13709", "Fail", ""]
        )

    def test_blanks_from_a_failed_run_are_replaced_too(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(power_run_status="Fail=2", CGR="")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "CGR")
        self.assertEqual(row[5:], ["99.37", "Fail", ""])

    def test_legitimate_zero_on_a_passing_run_is_preserved(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), qor_with(annotation_bb="0")),
            ("m2", default_compute(), qor_with(annotation_bb="0")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "annotation_bb")
        self.assertEqual(row[5:], ["0", "0", ""])

    def test_not_started_and_running_are_shown_verbatim(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), qor_with(power_run_status="Not Started")),
            ("m2", default_compute(), qor_with(power_run_status="Running")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "CGR")
        self.assertEqual(row[5:], ["Not Started", "Running", ""])

    def test_a_failing_baseline_suppresses_the_diff_for_a_passing_model(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), qor_with(power_run_status="Fail=2")),
            ("m2", default_compute(), default_qor()),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "CGR")
        self.assertEqual(row[5:], ["Fail", "99.37", ""])

    def test_every_metric_of_a_failed_key_is_replaced_including_real_elab_data(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", compute_with(power_run_status="Fail=2"), default_qor()),
        )
        table = cp.build_table(cfg, cp.COMPUTE)
        for metric in table.metrics:
            self.assertEqual(self._metric_row(table, metric)[6], "Fail", metric)
            self.assertEqual(self._metric_row(table, metric)[7], "", metric)

    def test_a_failed_elab_or_fsdb_status_does_not_touch_the_values(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", compute_with(elab_run_status="Fail=2", fsdb_run_status="Fail=2"), default_qor()),
        )
        row = self._metric_row(cp.build_table(cfg, cp.COMPUTE), "cell_count")
        self.assertEqual(row[5:], ["95549", "95549", "0.00"])

    def test_only_the_failing_model_column_is_affected(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(power_run_status="Fail=2")),
            ("m3", default_compute(), qor_with(CGR="110")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.QOR), "CGR")
        self.assertEqual(row[5:], ["99.37", "Fail", "110", "", "10.70", ""])


class TestComparisonPairs(unittest.TestCase):
    """Spec §7 item 9 -- baseline block then chained block (§3.7)."""

    def test_two_models_have_only_the_baseline_pair(self) -> None:
        self.assertEqual(cp.comparison_pairs(2), [(0, 1)])

    def test_chained_pairs_start_at_the_third_model(self) -> None:
        self.assertEqual(cp.comparison_pairs(3), [(0, 1), (0, 2), (1, 2)])
        self.assertEqual(
            cp.comparison_pairs(4), [(0, 1), (0, 2), (0, 3), (1, 2), (2, 3)]
        )

    def test_the_first_chain_link_is_never_duplicated(self) -> None:
        for count in range(2, 8):
            pairs = cp.comparison_pairs(count)
            self.assertEqual(len(pairs), len(set(pairs)), count)
            self.assertEqual(len(pairs), max(0, 2 * count - 3), count)


class TestStatusReport(unittest.TestCase):
    """Spec §7 item 10 -- the status/version report (§3.6)."""

    def test_kind_reads_qor_and_writes_its_own_file(self) -> None:
        self.assertEqual(cp.STATUS.source_filename, "report_pprtl2.qor.csv")
        self.assertEqual(cp.STATUS.output_filename, "compare_pprtl2.status.csv")

    def test_match_indicator_compares_strings_and_ignores_surrounding_space(self) -> None:
        self.assertEqual(cp.match_indicator({"a": "Pass"}, {"a": " Pass "}, "a"), "same")
        self.assertEqual(cp.match_indicator({"a": "Pass"}, {"a": "Fail=2"}, "a"), "changed")
        self.assertEqual(cp.match_indicator({"a": ""}, {"a": ""}, "a"), "same")

    def test_match_indicator_is_blank_when_a_row_is_missing(self) -> None:
        self.assertEqual(cp.match_indicator(None, {"a": "Pass"}, "a"), "")
        self.assertEqual(cp.match_indicator({"a": "Pass"}, None, "a"), "")


class TestStatusTable(_TableCase):
    """Spec §7 item 10 -- status/version rows, in file order, with same/changed."""

    def test_items_are_the_three_statuses_then_the_three_versions(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), default_qor()),
        )
        table = cp.build_table(cfg, cp.STATUS)
        self.assertEqual(table.metrics, [
            "elab_run_status", "fsdb_run_status", "power_run_status",
            "VCS_VERSION", "VERDI_VERSION", "PPRTL_VERSION",
        ])

    def test_header_uses_change_columns_not_percent_diff(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), default_qor()),
            ("m3", default_compute(), default_qor()),
        )
        self.assertEqual(cp.build_table(cfg, cp.STATUS).header, [
            "module", "power_mode", "test_name", "instance", "metric",
            "m1", "m2", "m3",
            "m2 vs m1 change", "m3 vs m1 change", "m3 vs m2 change",
        ])

    def test_identical_runs_are_all_same(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), default_qor()),
        )
        table = cp.build_table(cfg, cp.STATUS)
        for metric in table.metrics:
            self.assertEqual(self._metric_row(table, metric)[7], "same", metric)

    def test_status_change_is_reported_verbatim_with_the_exit_code(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(power_run_status="Fail=2")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.STATUS), "power_run_status")
        self.assertEqual(row[5:], ["Pass", "Fail=2", "changed"])

    def test_a_failed_run_does_not_blank_out_the_version_columns(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(power_run_status="Fail=2")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.STATUS), "VCS_VERSION")
        self.assertEqual(row[5:], ["X-2025.06-SP2-3", "X-2025.06-SP2-3", "same"])

    def test_tool_upgrade_shows_changed(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(PPRTL_VERSION="X-2025.09-SP1")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.STATUS), "PPRTL_VERSION")
        self.assertEqual(row[5:], ["X-2025.06-SP3-20260214", "X-2025.09-SP1", "changed"])

    def test_key_missing_from_one_model_yields_blank_value_and_blank_indicator(self) -> None:
        extra = qor_with(qor_row(module="newpartition"))
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), extra),
        )
        table = cp.build_table(cfg, cp.STATUS)
        row = self._metric_row(table, "power_run_status", module="newpartition")
        self.assertEqual(row[5:], ["", "Pass", ""])

    def test_chained_change_columns_track_the_neighbour(self) -> None:
        cfg = self._cfg(
            ("m1", default_compute(), default_qor()),
            ("m2", default_compute(), qor_with(power_run_status="Fail=2")),
            ("m3", default_compute(), qor_with(power_run_status="Fail=2")),
        )
        row = self._metric_row(cp.build_table(cfg, cp.STATUS), "power_run_status")
        self.assertEqual(
            row[5:], ["Pass", "Fail=2", "Fail=2", "changed", "changed", "same"]
        )


class TestGenerateReports(unittest.TestCase):
    """Spec §7 item 7 -- both files written, header always present, idempotent."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.outdir = self.root / "out"
        self.outdir.mkdir()
        self.cfg = cp.Config(
            models=(
                cp.ModelEntry(
                    name="m1",
                    workarea=make_workarea(self.root, "wa1", compute=default_compute(), qor=default_qor()),
                ),
                cp.ModelEntry(
                    name="m2",
                    workarea=make_workarea(
                        self.root, "wa2",
                        compute=compute_with(cell_count="96000"), qor=default_qor(),
                    ),
                ),
            ),
            outdir=self.outdir,
        )

    def _read(self, path: Path) -> list[list[str]]:
        with path.open(newline="", encoding="utf-8") as handle:
            return list(csv.reader(handle))

    def test_writes_every_report(self) -> None:
        written = cp.generate_reports(self.cfg)
        self.assertEqual(written, [
            self.cfg.compare_qor_csv,
            self.cfg.compare_compute_csv,
            self.cfg.compare_status_csv,
        ])
        for path in written:
            self.assertTrue(path.is_file(), path)

    def test_written_content_matches_the_built_table(self) -> None:
        cp.generate_reports(self.cfg)
        rows = self._read(self.cfg.compare_compute_csv)
        self.assertEqual(rows[0], [
            "module", "power_mode", "test_name", "instance", "metric",
            "m1", "m2", "m2 vs m1 % diff",
        ])
        self.assertIn(
            ["paraccasf", "vectorless", "default", "", "cell_count", "95549", "96000", "0.47"],
            rows,
        )

    def test_header_is_written_even_with_no_data_rows(self) -> None:
        empty = cp.Config(
            models=(
                cp.ModelEntry(
                    name="m1",
                    workarea=make_workarea(
                        self.root, "empty1", compute=COMPUTE_HEADER + "\n", qor=QOR_HEADER + "\n",
                    ),
                ),
                cp.ModelEntry(
                    name="m2",
                    workarea=make_workarea(
                        self.root, "empty2", compute=COMPUTE_HEADER + "\n", qor=QOR_HEADER + "\n",
                    ),
                ),
            ),
            outdir=self.outdir,
        )
        cp.generate_reports(empty)
        rows = self._read(empty.compare_qor_csv)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0][:5], ["module", "power_mode", "test_name", "instance", "metric"])

    def test_rerunning_is_idempotent(self) -> None:
        cp.generate_reports(self.cfg)
        first = {p: p.read_bytes() for p in (self.cfg.compare_qor_csv, self.cfg.compare_compute_csv)}
        cp.generate_reports(self.cfg)
        for path, content in first.items():
            self.assertEqual(path.read_bytes(), content)

    def test_stale_content_is_overwritten_not_appended(self) -> None:
        self.cfg.compare_qor_csv.write_text("stale,junk\n" * 50, encoding="utf-8")
        cp.generate_reports(self.cfg)
        text = self.cfg.compare_qor_csv.read_text(encoding="utf-8")
        self.assertNotIn("stale", text)


class TestCli(unittest.TestCase):
    """Spec §5 -- exit codes and the --dry-run plan (phase 1 subset of item 7)."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.outdir = self.root / "out"
        self.outdir.mkdir()
        self.wa1 = make_workarea(self.root, "wa1", compute=default_compute(), qor=default_qor())
        self.wa2 = make_workarea(self.root, "wa2", compute=default_compute(), qor=default_qor())
        self.models = self.root / "models.md"
        self.models.write_text(f"m1={self.wa1}\nm2={self.wa2}\n", encoding="utf-8")

    def _argv(self, *extra: str) -> list[str]:
        return [
            "--models-for-compare", str(self.models),
            "--outdir", str(self.outdir),
            *extra,
        ]

    def _main(self, *extra: str) -> int:
        """Run main() with stdout/stderr captured so test output stays clean."""
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return cp.main(self._argv(*extra))

    def test_dry_run_exits_zero_and_writes_nothing(self) -> None:
        self.assertEqual(self._main("--dry-run"), 0)
        self.assertEqual(list(self.outdir.iterdir()), [])

    def test_real_run_exits_zero_and_writes_every_report(self) -> None:
        self.assertEqual(self._main(), 0)
        self.assertEqual(
            sorted(p.name for p in self.outdir.iterdir()),
            [
                "compare_pprtl2.compute.csv",
                "compare_pprtl2.qor.csv",
                "compare_pprtl2.status.csv",
            ],
        )

    def test_force_is_a_no_op(self) -> None:
        self.assertEqual(self._main(), 0)
        before = {p: p.read_bytes() for p in self.outdir.iterdir()}
        self.assertEqual(self._main("--force"), 0)
        for path, content in before.items():
            self.assertEqual(path.read_bytes(), content)

    def test_bad_models_file_exits_two(self) -> None:
        self.models.write_text("only-one=/wa/one\n", encoding="utf-8")
        self.assertEqual(self._main("--dry-run"), 2)

    def test_preflight_failure_exits_two(self) -> None:
        (self.wa1 / "power" / "pprtl2" / "report_pprtl2.qor.csv").unlink()
        self.assertEqual(self._main("--dry-run"), 2)

    def test_plan_names_every_output_and_the_baseline(self) -> None:
        cfg = cp.Config(
            models=(
                cp.ModelEntry(name="m1", workarea=self.wa1),
                cp.ModelEntry(name="m2", workarea=self.wa2),
            ),
            outdir=self.outdir,
        )
        plan = "\n".join(cp.render_plan(cfg))
        self.assertIn(str(self.outdir / "compare_pprtl2.qor.csv"), plan)
        self.assertIn(str(self.outdir / "compare_pprtl2.compute.csv"), plan)
        self.assertIn(str(self.outdir / "compare_pprtl2.status.csv"), plan)
        self.assertIn(f"Baseline model: m1 = {self.wa1}", plan)
        self.assertIn(f"  m2 = {self.wa2}", plan)
        self.assertNotIn("Chain order:", plan)

    def test_plan_shows_the_chain_order_for_three_or_more_models(self) -> None:
        cfg = cp.Config(
            models=(
                cp.ModelEntry(name="m1", workarea=self.wa1),
                cp.ModelEntry(name="m2", workarea=self.wa2),
                cp.ModelEntry(name="m3", workarea=self.wa2),
            ),
            outdir=self.outdir,
        )
        self.assertIn("Chain order: m1 -> m2 -> m3", "\n".join(cp.render_plan(cfg)))

    def test_outdir_defaults_to_cwd(self) -> None:
        args = cp.build_arg_parser().parse_args(["--models-for-compare", str(self.models)])
        self.assertEqual(cp.resolve_config(args).outdir, Path.cwd())


if __name__ == "__main__":
    unittest.main()
