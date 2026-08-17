#!/usr/bin/env python3
"""Unit tests for report_pprtl2 (see report_pprtl2.spec.md §7 test plan, items 1-7).

Run:  python3 -m unittest test_report_pprtl2 -v
  or: python3 test_report_pprtl2.py
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import report_pprtl2 as rp

CONFIG_TABLE_FIXTURE = """\
+-----------------------------+-----------------------+--------------+
| Config                      | Value                 | Source       |
+-----------------------------+-----------------------+--------------+
| BLOCK                       |                        | Default      |
| DUT                         | imh                    | Env/Cmd-line |
| TOP_IP_NAME                 | imh                    | Env/Cmd-line |
| TOP_MODULE_NAME             | hamvf                  | Env/Cmd-line |
| PASS                        | hamvf_pass01           | User-cfg     |
| POWER_ANALYSIS_MODE         | vectorless             | User-cfg     |
| SDC_FILE                    | /a/first.tcl           | User-cfg     |
| SDC_FILE                    | /a/second.tcl          | User-cfg     |
| SKIP_STAGES                 |                        | Default      |
+-----------------------------+-----------------------+--------------+
"""

def rtl_metrics_hier_csv(module: str, **overrides: str) -> str:
    """Minimal ``<module>.rtl_metrics.hier.csv`` fixture (S25): header + the
    module's own top-of-hierarchy row (``Hierarchy Level`` == "0"). Only
    includes the columns report_pprtl2 actually reads -- the real file has
    100+ power/toggle-rate columns we never look at.
    """
    values = {
        "All Cell Count": "2750050",
        "Combinational Cell Count": "2593697",
        "Sequential Cell Count": "47",
        "Register Cell Count": "85560",
        "Register Bit Count": "245556",
        "CGR (%)": "97.16",
        "CGE (%)": "64.78",
        "DACGE (%)": "75.45",
        "Flop Cell Count": "1349",
        "MBFlop Cell Count": "794",
        "EQFB": "6765",
        "Latch Cell Count": "17",
        "MBLatch Cell Count": "204",
        "EQLB": "833",
        "Hierarchy Level": "0",
        "Module Name": module,
    }
    values.update(overrides)
    header = ",".join(values.keys())
    row = ",".join(values.values())
    return header + "\n" + row + "\n"


STAT2_RPT_FIXTURE = """\
##########################################################################
Total power: 432.03699
SCGE: 99.26
DCGE: 80.47
DACGE: 88.87
Total cell count: 2106891
Register Count: 116488
Sequential cells count: 2882
Untraced Sequential ratio: 0.024143419619669933
Primary I/P annotation: 146(100%)
Black Box annotation: 16(72.73%)
Sequential annotation: 17,816(99.70%)
Maximum memory usage for this session: 9349076
Elapsed time for this session: 2047.17
##########################################################################
"""

VCS_LOG_FIXTURE = """\
                         Chronologic VCS (TM)
      Version X-2025.06-SP2-3_Full64 -- Tue Aug 11 21:23:30 2026

"""

ELAB_VERSION_LINES_FIXTURE = (
    "[21:21:41 2026-08-11] [INFO ] Info: VERDI_HOME = "
    "/p/hdk/rtl/cad/x86-64_linux26/synopsys/verdi3/X-2025.06-SP2\n"
    "[21:21:43 2026-08-11] [INFO ] PrimePower RTL [Wattson Inside] (R)\n"
    "[21:21:43 2026-08-11] [INFO ] \n"
    "[21:21:43 2026-08-11] [INFO ] Version: X-2025.06-SP3-20260214 for linux64 - Feb 14, 2026\n"
)

GRDLBUILD_FOOTER_FIXTURE = """\
[20:23:57 2026-07-23] [INFO ] elab stage passed successfully..
+-----------------------------------------------------------------------------+
| Exit Status    : 0                                                          |
| Finishing time : Thu Jul 23 20:23:59 2026                                   |
| CPU time       : Usr 24163.46s Sys 1931.53s WC  3h:00m:37s
 |
| Rusage Stats   : Mem:183730 PF:  133182307/CSv/f:  0/0     Swaps:0          |
+-----------------------------------------------------------------------------+
"""

GRDLBUILD_FAIL_FOOTER_FIXTURE = """\
+-----------------------------------------------------------------------------+
| Exit Status    : 2                                                          |
| Finishing time : Thu Jul 23 22:47:18 2026                                   |
| CPU time       : Usr 100.0s Sys 10.0s WC  0h:06m:15s
 |
| Rusage Stats   : Mem:4096 PF:  0/0     Swaps:0          |
+-----------------------------------------------------------------------------+
"""

FLOW_LOG_FIXTURE = """\
[20:23:53 2026-07-23] [INFO ] Maximum memory usage for this session: 137,448,272 KB (131.08 GB)
[20:23:53 2026-07-23] [INFO ] CPU usage for this session: 9168.46 seconds (2.55 hours)
[20:23:53 2026-07-23] [INFO ] Elapsed time for this session: 10824.7 seconds (3.01 hours)
[20:23:57 2026-07-23] [INFO ] elab stage passed successfully..
"""

FLOW_LOG_RUNNING_FIXTURE = """\
[20:23:53 2026-07-23] [INFO ] Executing command locally: 'pprtl -f foo.tcl -batch'
[20:23:54 2026-07-23] [INFO ] Info: Start time = Thu Jul 23 20:23:54 2026
"""

GRDLBUILD_RUNNING_FIXTURE = """\
+-----------------------------------------------------------------------------+
| Logfile        : power.paraccasf.pprtl2_elab.log                            |
| Job id         : 1627979645                 Class: SLES15SP4&&384G&&4C      |
| Starting time  : Mon Aug 10 21:16:05 2026                                   |
+-----------------------------------------------------------------------------+
-GRADLE- Logfile: /some/path/power.paraccasf.pprtl2_elab.log
-GRADLE- The task full command: /usr/intel/bin/tcsh -fc "make elab"
"""


class TestConfigTableParsing(unittest.TestCase):
    """§7 test plan item 1 — S1 config.log table parsing."""

    def test_parses_table_first_occurrence_wins(self) -> None:
        values = rp.parse_config_table(CONFIG_TABLE_FIXTURE)
        self.assertEqual(values["TOP_MODULE_NAME"], "hamvf")
        self.assertEqual(values["TOP_IP_NAME"], "imh")
        self.assertEqual(values["DUT"], "imh")
        self.assertEqual(values["PASS"], "hamvf_pass01")
        self.assertEqual(values["POWER_ANALYSIS_MODE"], "vectorless")
        self.assertEqual(values["SDC_FILE"], "/a/first.tcl")  # first wins
        self.assertEqual(values["BLOCK"], "")
        self.assertEqual(values["SKIP_STAGES"], "")
        self.assertNotIn("Config", values)


class TestReportParsers(unittest.TestCase):
    """§7 test plan item 1 — report-file parsing (rtl_metrics.hier.csv/stat2)."""

    def test_rtl_metrics_hier_csv(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "hamvf.rtl_metrics.hier.csv"
            path.write_text(rtl_metrics_hier_csv("hamvf"), encoding="utf-8")
            row = rp.parse_rtl_metrics_hier_csv(path, "hamvf")
            self.assertEqual(row["cell_count"], 2750050)
            self.assertEqual(row["combinational_cell_count"], 2593697)
            self.assertEqual(row["unclocked_sequential_cell_count"], 47)
            self.assertEqual(row["register_cell_count"], 85560)
            self.assertEqual(row["register_bit_count"], 245556)
            self.assertEqual(row["CGR"], 97.16)
            self.assertEqual(row["CGE"], 64.78)
            self.assertEqual(row["DACGE"], 75.45)
            self.assertEqual(row["flop_cell_count"], 1349)
            self.assertEqual(row["mbflop_cell_count"], 794)
            self.assertEqual(row["eqfb"], 6765)
            self.assertEqual(row["latch_cell_count"], 17)
            self.assertEqual(row["mblatch_cell_count"], 204)
            self.assertEqual(row["eqlb"], 833)

    def test_rtl_metrics_hier_csv_module_not_found(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "hamvf.rtl_metrics.hier.csv"
            path.write_text(rtl_metrics_hier_csv("hamvf"), encoding="utf-8")
            self.assertIsNone(rp.parse_rtl_metrics_hier_csv(path, "nope"))

    def test_rtl_metrics_hier_csv_missing_file(self) -> None:
        self.assertIsNone(rp.parse_rtl_metrics_hier_csv(Path("/no/such/file.csv"), "hamvf"))

    def test_rtl_metrics_hier_csv_stops_at_first_matching_row(self) -> None:
        """The module's own row is always first on real data, but the parser
        must match on Hierarchy Level 0 and stop there -- not be fooled by a
        later row that happens to repeat the same values."""
        text = (
            "All Cell Count,Hierarchy Level,Module Name\n"
            "111,0,hamvf\n"
            "999,0,hamvf\n"
        )
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "hamvf.rtl_metrics.hier.csv"
            path.write_text(text, encoding="utf-8")
            row = rp.parse_rtl_metrics_hier_csv(path, "hamvf")
            self.assertEqual(row["cell_count"], 111)

    def test_stat2_rpt(self) -> None:
        kv = rp.parse_keyvalue_report(STAT2_RPT_FIXTURE)
        self.assertEqual(kv["Total cell count"], "2106891")
        self.assertEqual(kv["Register Count"], "116488")
        self.assertEqual(kv["Sequential cells count"], "2882")
        self.assertEqual(kv["SCGE"], "99.26")
        self.assertEqual(kv["Untraced Sequential ratio"], "0.024143419619669933")
        self.assertEqual(kv["Primary I/P annotation"], "146(100%)")
        self.assertEqual(kv["Black Box annotation"], "16(72.73%)")
        self.assertEqual(kv["Sequential annotation"], "17,816(99.70%)")


class TestVersionInfo(unittest.TestCase):
    """§7 test plan item 1 — VCS_VERSION/VERDI_VERSION/PPRTL_VERSION extraction."""

    def test_extracts_all_three_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            vcs_log = tmp_path / "vcs.log"
            vcs_log.write_text(VCS_LOG_FIXTURE, encoding="utf-8")
            elab_log = tmp_path / "elab.log"
            elab_log.write_text(ELAB_VERSION_LINES_FIXTURE + GRDLBUILD_FOOTER_FIXTURE, encoding="utf-8")

            info = rp.extract_version_info(vcs_log, elab_log)
            self.assertEqual(info["VCS_VERSION"], "X-2025.06-SP2-3")  # trailing _Full64 trimmed
            self.assertEqual(info["VERDI_VERSION"], "X-2025.06-SP2")
            self.assertEqual(info["PPRTL_VERSION"], "X-2025.06-SP3-20260214")

    def test_blank_when_logs_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            info = rp.extract_version_info(tmp_path / "nope.log", tmp_path / "nope2.log")
            self.assertIsNone(info["VCS_VERSION"])
            self.assertIsNone(info["VERDI_VERSION"])
            self.assertIsNone(info["PPRTL_VERSION"])

    def test_vcs_version_without_full64_suffix_is_unchanged(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            vcs_log = tmp_path / "vcs.log"
            vcs_log.write_text(
                "                         Chronologic VCS (TM)\n"
                "      Version X-2025.06-SP2 -- Tue Aug 11 21:23:30 2026\n",
                encoding="utf-8",
            )
            info = rp.extract_version_info(vcs_log, tmp_path / "nope.log")
            self.assertEqual(info["VCS_VERSION"], "X-2025.06-SP2")


class TestNetbatchAndFlowLogFooters(unittest.TestCase):
    """§7 test plan item 1 — S2 netbatch footer + flow.log footer parsing."""

    def test_grdlbuild_footer(self) -> None:
        parsed = rp.parse_grdlbuild_footer(GRDLBUILD_FOOTER_FIXTURE)
        self.assertEqual(parsed["exit_code"], 0)
        self.assertEqual(parsed["runtime_seconds"], 3 * 3600 + 37)
        self.assertAlmostEqual(parsed["memory_gb"], 183.73)

    def test_grdlbuild_footer_with_days(self) -> None:
        text = "| Exit Status    : 0 |\n| CPU time : WC  1d:14h:47m:11s |\n| Rusage Stats : Mem:1000 |"
        parsed = rp.parse_grdlbuild_footer(text)
        self.assertEqual(parsed["runtime_seconds"], 86400 + 14 * 3600 + 47 * 60 + 11)
        self.assertAlmostEqual(parsed["memory_gb"], 1.0)

    def test_grdlbuild_footer_fail(self) -> None:
        parsed = rp.parse_grdlbuild_footer(GRDLBUILD_FAIL_FOOTER_FIXTURE)
        self.assertEqual(parsed["exit_code"], 2)

    def test_flow_log_footer(self) -> None:
        parsed = rp.parse_flow_log_footer(FLOW_LOG_FIXTURE)
        self.assertEqual(parsed["runtime_seconds"], 10824.7)
        self.assertAlmostEqual(parsed["memory_gb"], 131.08)

    def test_format_runtime(self) -> None:
        self.assertEqual(rp.format_runtime(10837.0), "00d:03h:00m:37s")
        self.assertEqual(rp.format_runtime(86400 + 3661), "01d:01h:01m:01s")
        self.assertEqual(rp.format_runtime(None), "")


class TestEvaluateStage(unittest.TestCase):
    """§7 test plan item 2 — grdlbuild-only Pass/Fail/Running/Not-Started determination."""

    def test_pass_via_grdlbuild_footer(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            grdl_log = Path(tmp) / "grdl.log"
            grdl_log.write_text(GRDLBUILD_FOOTER_FIXTURE, encoding="utf-8")
            result = rp.evaluate_stage(grdlbuild_log=grdl_log)
            self.assertEqual(result.status, "Pass")
            self.assertEqual(result.runtime_seconds, 3 * 3600 + 37)

    def test_fail_via_grdlbuild_exit_code(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            grdl_log = Path(tmp) / "grdl.log"
            grdl_log.write_text(GRDLBUILD_FAIL_FOOTER_FIXTURE, encoding="utf-8")
            result = rp.evaluate_stage(grdlbuild_log=grdl_log)
            self.assertEqual(result.status, "Fail=2")

    def test_running_when_log_exists_but_no_exit_status_footer(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            grdl_log = Path(tmp) / "grdl.log"
            grdl_log.write_text(GRDLBUILD_RUNNING_FIXTURE, encoding="utf-8")
            result = rp.evaluate_stage(grdlbuild_log=grdl_log)
            self.assertEqual(result.status, "Running")

    def test_not_started_when_grdlbuild_log_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = rp.evaluate_stage(grdlbuild_log=Path(tmp) / "nope.log")
            self.assertEqual(result.status, "Not Started")

    def test_flow_log_fills_in_missing_runtime_and_memory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            grdl_log = Path(tmp) / "grdl.log"
            grdl_log.write_text("| Exit Status    : 0 |\n", encoding="utf-8")  # no WC/Mem in footer
            flow_log = Path(tmp) / "flow.log"
            flow_log.write_text(FLOW_LOG_FIXTURE, encoding="utf-8")
            result = rp.evaluate_stage(grdlbuild_log=grdl_log, flow_log=flow_log)
            self.assertEqual(result.status, "Pass")
            self.assertEqual(result.runtime_seconds, 10824.7)
            self.assertAlmostEqual(result.memory_gb, 131.08)


class TestQorExtraction(unittest.TestCase):
    """§7 test plan item 3 — QoR precedence rules (S25 primary, stat2 annotations-only)."""

    def _write_rtl_metrics(self, tmp: Path, module: str, **overrides: str) -> Path:
        reports_dir = tmp / "reports"
        reports_dir.mkdir(parents=True, exist_ok=True)
        (reports_dir / f"{module}.rtl_metrics.hier.csv").write_text(
            rtl_metrics_hier_csv(module, **overrides), encoding="utf-8",
        )
        return reports_dir

    def test_vectorless_uses_rtl_metrics_hier_csv(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            reports_dir = self._write_rtl_metrics(Path(tmp), "hamvf")
            qor = rp.extract_qor_fields(reports_dir, "hamvf", "vectorless", None)
            self.assertEqual(qor["cell_count"], 2750050)
            self.assertEqual(qor["combinational_cell_count"], 2593697)
            self.assertEqual(qor["register_cell_count"], 85560)
            self.assertEqual(qor["unclocked_sequential_cell_count"], 47)
            self.assertEqual(qor["register_bit_count"], 245556)
            self.assertEqual(qor["CGR"], 97.16)
            self.assertEqual(qor["CGE"], 64.78)
            self.assertEqual(qor["DACGE"], 75.45)
            self.assertEqual(qor["flop_cell_count"], 1349)
            self.assertEqual(qor["mbflop_cell_count"], 794)
            self.assertEqual(qor["eqfb"], 6765)
            self.assertEqual(qor["latch_cell_count"], 17)
            self.assertEqual(qor["mblatch_cell_count"], 204)
            self.assertEqual(qor["eqlb"], 833)
            # untraced = 47/(85560+47)*100
            self.assertAlmostEqual(qor["untraced_sequentials_percentage"], 0.05, places=2)
            # vectorless mode never reads stat2 -- annotations stay blank
            self.assertIsNone(qor["annotation_primary_io"])

    def test_rtl_metrics_wins_over_stat2_for_timebased(self) -> None:
        """rtl_metrics.hier.csv is now primary even for timebased mode -- a
        stat2.rpt with DIFFERENT overlapping values must NOT override it."""
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            reports_dir = self._write_rtl_metrics(tmp_path, "d2d1")
            stat2_path = reports_dir / "d2d1.stat2.rpt"
            stat2_path.write_text(STAT2_RPT_FIXTURE, encoding="utf-8")  # distinct cell counts
            qor = rp.extract_qor_fields(reports_dir, "d2d1", "timebased", stat2_path)
            self.assertEqual(qor["cell_count"], 2750050)  # from rtl_metrics, not stat2's 2106891
            self.assertEqual(qor["register_cell_count"], 85560)
            self.assertEqual(qor["CGR"], 97.16)  # not stat2's SCGE (99.26)

    def test_stat2_supplies_annotations_for_timebased_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            reports_dir = self._write_rtl_metrics(tmp_path, "d2d1")
            stat2_path = reports_dir / "d2d1.stat2.rpt"
            stat2_path.write_text(STAT2_RPT_FIXTURE, encoding="utf-8")
            qor = rp.extract_qor_fields(reports_dir, "d2d1", "timebased", stat2_path)
            self.assertEqual(qor["annotation_primary_io"], 100.0)
            self.assertEqual(qor["annotation_bb"], 72.73)
            self.assertEqual(qor["annotation_seq"], 99.70)

    def test_missing_rtl_metrics_csv_yields_blank_fields(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            reports_dir = Path(tmp) / "reports"
            reports_dir.mkdir(parents=True)
            qor = rp.extract_qor_fields(reports_dir, "hamvf", "vectorless", None)
            self.assertIsNone(qor["cell_count"])
            self.assertIsNone(qor["CGR"])
            self.assertIsNone(qor["untraced_sequentials_percentage"])

    def test_annotation_fields_keep_percentage_only(self) -> None:
        self.assertEqual(rp._extract_annotation_pct("4,075(96.75%)"), 96.75)
        self.assertEqual(rp._extract_annotation_pct("146(100%)"), 100.0)
        self.assertIsNone(rp._extract_annotation_pct(None))
        self.assertIsNone(rp._extract_annotation_pct("no percentage here"))


class TestBuildRows(unittest.TestCase):
    """§7 test plan item 4 — integration: discovery + row assembly against a fake tree."""

    def _make_pass_dir(self, root: Path, dut: str, module: str, pass_name: str, top_ip: str = "imh") -> Path:
        pass_dir = root / "output" / dut / "pprtl2" / pass_name
        flow_inputs = pass_dir / "flow_inputs"
        flow_inputs.mkdir(parents=True)
        config_text = (
            "+------+------+------+\n"
            "| Config | Value | Source |\n"
            "+------+------+------+\n"
            "| BLOCK |  | Default |\n"
            f"| DUT | {dut} | Env/Cmd-line |\n"
            f"| TOP_IP_NAME | {top_ip} | Env/Cmd-line |\n"
            f"| TOP_MODULE_NAME | {module} | Env/Cmd-line |\n"
            f"| PASS | {pass_name} | User-cfg |\n"
            "+------+------+------+\n"
        )
        (flow_inputs / "config.log").write_text(config_text, encoding="utf-8")
        return pass_dir

    def _write_grdlbuild(self, root: Path, module: str, activity: str, text: str) -> None:
        path = rp.grdlbuild_log_path(root, module, activity)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def _write_partition_list(self, root: Path, modules: list[str]) -> None:
        out_root = root / "power" / "pprtl2"
        out_root.mkdir(parents=True, exist_ok=True)
        (out_root / "prep_pprtl2_partition.list").write_text("\n".join(modules) + "\n", encoding="utf-8")

    def test_vectorless_module_produces_one_row(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pass_dir = self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            self._write_partition_list(root, ["hamvf"])
            self._write_grdlbuild(root, "hamvf", "elab", ELAB_VERSION_LINES_FIXTURE + GRDLBUILD_FOOTER_FIXTURE)
            self._write_grdlbuild(root, "hamvf", "power_vectorless", GRDLBUILD_FOOTER_FIXTURE)

            reports_dir = pass_dir / "power" / "vectorless" / "default" / "reports"
            reports_dir.mkdir(parents=True)
            (reports_dir / "hamvf.rtl_metrics.hier.csv").write_text(
                rtl_metrics_hier_csv("hamvf"), encoding="utf-8",
            )
            vcs_log = pass_dir / "elab" / "pprtl_work" / "vcs" / "vcs.log"
            vcs_log.parent.mkdir(parents=True)
            vcs_log.write_text(VCS_LOG_FIXTURE, encoding="utf-8")

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            self.assertIn("hamvf", chosen)
            row = rows[0]
            self.assertEqual(row.power_mode, "vectorless")
            self.assertEqual(row.test_name, "default")
            self.assertEqual(row.elab.status, "Pass")
            self.assertEqual(row.power.status, "Pass")
            self.assertEqual(row.fsdb.status, "Not Required")
            self.assertEqual(row.qor["cell_count"], 2750050)
            self.assertEqual(row.qor["VCS_VERSION"], "X-2025.06-SP2-3")  # trailing _Full64 trimmed
            self.assertEqual(row.qor["VERDI_VERSION"], "X-2025.06-SP2")
            self.assertEqual(row.qor["PPRTL_VERSION"], "X-2025.06-SP3-20260214")
            self.assertEqual(module_status["hamvf"].elab.status, "Pass")
            self.assertEqual(module_status["hamvf"].vectorless_power.status, "Pass")
            self.assertIsNone(module_status["hamvf"].fsdb)
            self.assertIsNone(module_status["hamvf"].timebased_power)

    def test_newest_pass_dir_selected_per_module(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            old_dir = self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            new_dir = self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass02")
            # make new_dir's mtime clearly newer
            import time
            os_stat_time = time.time() + 1000
            import os as _os
            _os.utime(new_dir, (os_stat_time, os_stat_time))

            candidates = rp.find_pass_candidates(root, "imh")
            chosen = rp.select_newest_per_module(candidates)
            self.assertEqual(chosen["hamvf"].pass_dir, new_dir)
            self.assertNotEqual(chosen["hamvf"].pass_dir, old_dir)

    def test_partition_style_layout_also_discovered(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pass_dir = root / "output" / "imh" / "partition" / "parfws" / "pprtl2" / "parfws_pass01"
            flow_inputs = pass_dir / "flow_inputs"
            flow_inputs.mkdir(parents=True)
            config_text = (
                "| Config | Value | Source |\n"
                "| BLOCK | parfws | Env/Cmd-line |\n"
                "| TOP_IP_NAME | parfws | Env/Cmd-line |\n"
                "| TOP_MODULE_NAME | parfws | Env/Cmd-line |\n"
            )
            (flow_inputs / "config.log").write_text(config_text, encoding="utf-8")

            candidates = rp.find_pass_candidates(root, "imh")
            self.assertEqual(len(candidates), 1)
            self.assertEqual(candidates[0].module, "parfws")
            self.assertEqual(candidates[0].config["BLOCK"], "parfws")

    def test_all_partitions_in_partition_list_are_accounted_for(self) -> None:
        """Every module in S20 (partition.list) must produce >=1 row, even if it
        never reached the power stage or was never discovered/started at all."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            self._write_partition_list(root, ["hamvf", "ghost_module"])
            self._write_grdlbuild(root, "hamvf", "elab", GRDLBUILD_FOOTER_FIXTURE)
            self._write_grdlbuild(root, "hamvf", "power_vectorless", GRDLBUILD_FOOTER_FIXTURE)

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            modules = {r.module for r in rows}
            self.assertEqual(modules, {"hamvf", "ghost_module"})
            self.assertNotIn("ghost_module", chosen)

            ghost_row = next(r for r in rows if r.module == "ghost_module")
            self.assertEqual(ghost_row.elab.status, "Not Started")
            self.assertEqual(ghost_row.power.status, "Not Started")
            self.assertEqual(module_status["ghost_module"].elab.status, "Not Started")
            self.assertEqual(module_status["ghost_module"].vectorless_power.status, "Not Started")

    def test_elab_only_module_with_no_power_dir_yet_produces_fallback_row(self) -> None:
        """A module whose elab passed but whose power stage never started (no
        grdlbuild power_vectorless log yet) must still get one row."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            self._write_partition_list(root, ["hamvf"])
            self._write_grdlbuild(root, "hamvf", "elab", GRDLBUILD_FOOTER_FIXTURE)
            # NB: no power_vectorless grdlbuild log and no power/ dir at all.

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            row = rows[0]
            self.assertEqual(row.module, "hamvf")
            self.assertEqual(row.power_mode, "vectorless")
            self.assertEqual(row.test_name, "default")
            self.assertEqual(row.elab.status, "Pass")
            self.assertEqual(row.fsdb.status, "Not Required")
            self.assertEqual(row.power.status, "Not Started")

    def test_elab_failed_module_reports_fail_status(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "parmiocxlrx_pcu", "parmiocxlrx_pcu_pass01")
            self._write_partition_list(root, ["parmiocxlrx_pcu"])
            self._write_grdlbuild(root, "parmiocxlrx_pcu", "elab", GRDLBUILD_FAIL_FOOTER_FIXTURE)

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            row = rows[0]
            self.assertEqual(row.elab.status, "Fail=2")
            self.assertEqual(row.power.status, "Not Started")

    def test_elab_running_when_grdlbuild_log_has_no_footer_yet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            self._write_partition_list(root, ["hamvf"])
            self._write_grdlbuild(root, "hamvf", "elab", GRDLBUILD_RUNNING_FIXTURE)

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            self.assertEqual(rows[0].elab.status, "Running")

    def test_timebased_module_with_two_tests_shares_module_level_fsdb_power_status(self) -> None:
        """fsdb/timebased-power are ONE grdlbuild task per module (not per test)
        -- both test rows must share the exact same fsdb/power StageResult."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pass_dir = self._make_pass_dir(root, "imh", "d2d1", "d2d1_pass01")
            self._write_grdlbuild(root, "d2d1", "elab", GRDLBUILD_FOOTER_FIXTURE)
            self._write_grdlbuild(root, "d2d1", "fsdb", GRDLBUILD_FOOTER_FIXTURE)
            self._write_grdlbuild(root, "d2d1", "power_timebased", GRDLBUILD_FAIL_FOOTER_FIXTURE)

            for test_name in ("test_a", "test_b"):
                inst_dir = pass_dir / "power" / "timebased" / test_name / "d2d_1_d2d1"
                reports_dir = inst_dir / "reports"
                reports_dir.mkdir(parents=True)
                (reports_dir / "d2d1.stat2.rpt").write_text(STAT2_RPT_FIXTURE, encoding="utf-8")
                (reports_dir / "d2d1.rtl_metrics.hier.csv").write_text(
                    rtl_metrics_hier_csv("d2d1"), encoding="utf-8",
                )

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            self.assertEqual(len(rows), 2)
            self.assertEqual({r.test_name for r in rows}, {"test_a", "test_b"})
            for r in rows:
                self.assertEqual(r.power_mode, "timebased")
                self.assertEqual(r.instance, "d2d_1_d2d1")
                self.assertEqual(r.elab.status, "Pass")
                self.assertEqual(r.fsdb.status, "Pass")
                self.assertEqual(r.power.status, "Fail=2")  # shared module-level status
                self.assertEqual(r.qor["cell_count"], 2750050)  # from rtl_metrics.hier.csv (precedence)
                self.assertEqual(r.qor["annotation_primary_io"], 100.0)  # from stat2, pct-only
            self.assertEqual(module_status["d2d1"].fsdb.status, "Pass")
            self.assertEqual(module_status["d2d1"].timebased_power.status, "Fail=2")

    def test_timebased_target_with_no_test_dirs_yet_produces_one_not_started_row(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "d2d1", "d2d1_pass01")
            out_root = root / "power" / "pprtl2"
            out_root.mkdir(parents=True)
            (out_root / "prep_pprtl2_timebased_partition.list").write_text("d2d1\n", encoding="utf-8")
            self._write_grdlbuild(root, "d2d1", "elab", GRDLBUILD_FOOTER_FIXTURE)
            # NB: no fsdb/power_timebased grdlbuild logs, no power/timebased dir on disk.

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            row = rows[0]
            self.assertEqual(row.power_mode, "timebased")
            self.assertEqual(row.test_name, "")
            self.assertEqual(row.fsdb.status, "Not Started")
            self.assertEqual(row.power.status, "Not Started")


class TestReadPartitionList(unittest.TestCase):
    """§7 test plan item 1 — S20 (prep_pprtl2_partition.list) parsing."""

    def test_parses_bare_names_skips_comments_and_blanks(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "prep_pprtl2_partition.list"
            path.write_text("parfws\n\n# a comment\nparocs\n", encoding="utf-8")
            self.assertEqual(rp.read_partition_list(path), ["parfws", "parocs"])

    def test_missing_file_returns_empty_list(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(rp.read_partition_list(Path(tmp) / "nope.list"), [])


class TestPreflightAndCli(unittest.TestCase):
    """§7 test plan item 5 — CLI/pre-flight validation (spec section 2.1) and main() exit codes."""

    def _make_valid_workarea(self, root: Path) -> None:
        (root / "output" / "imh" / "pprtl2").mkdir(parents=True)
        (root / "power" / "pprtl2").mkdir(parents=True)

    def test_preflight_missing_workarea(self) -> None:
        cfg = rp.Config(dut="imh", workarea=Path("/no/such/workarea/xyz"))
        errors = rp.preflight(cfg)
        self.assertTrue(any("workarea not found" in e for e in errors))

    def test_preflight_missing_output_run_area(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "power" / "pprtl2").mkdir(parents=True)
            cfg = rp.Config(dut="imh", workarea=root)
            errors = rp.preflight(cfg)
            self.assertTrue(any("no power output run area found" in e for e in errors))

    def test_preflight_missing_power_pprtl2_out_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "output" / "imh" / "pprtl2").mkdir(parents=True)
            cfg = rp.Config(dut="imh", workarea=root)
            errors = rp.preflight(cfg)
            self.assertTrue(any("does not exist" in e for e in errors))

    def test_preflight_passes_for_valid_workarea(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_valid_workarea(root)
            cfg = rp.Config(dut="imh", workarea=root)
            self.assertEqual(rp.preflight(cfg), [])

    def test_resolve_config_uses_workarea_env_when_arg_missing(self) -> None:
        import os as _os
        with tempfile.TemporaryDirectory() as tmp:
            args = rp.build_arg_parser().parse_args(["--dut", "imh"])
            old = _os.environ.get("WORKAREA")
            _os.environ["WORKAREA"] = tmp
            try:
                cfg = rp.resolve_config(args)
                self.assertEqual(cfg.workarea, Path(tmp).resolve())
            finally:
                if old is None:
                    _os.environ.pop("WORKAREA", None)
                else:
                    _os.environ["WORKAREA"] = old

    def test_resolve_config_raises_without_workarea_or_env(self) -> None:
        import os as _os
        args = rp.build_arg_parser().parse_args(["--dut", "imh"])
        old = _os.environ.pop("WORKAREA", None)
        try:
            with self.assertRaises(SystemExit):
                rp.resolve_config(args)
        finally:
            if old is not None:
                _os.environ["WORKAREA"] = old

    def test_command_line_reconstruction(self) -> None:
        self.assertEqual(
            rp._command_line(["--dut", "imh", "--workarea", "/wa"]),
            "report_pprtl2.py --dut imh --workarea /wa",
        )

    def test_main_exits_2_when_preflight_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            rc = rp.main(["--dut", "imh", "--workarea", tmp])
            self.assertEqual(rc, 2)

    def test_main_exits_2_when_no_rows_discovered(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_valid_workarea(root)
            rc = rp.main(["--dut", "imh", "--workarea", str(root)])
            self.assertEqual(rc, 2)

    def test_main_dry_run_writes_nothing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_valid_workarea(root)
            (root / "power" / "pprtl2" / "prep_pprtl2_partition.list").write_text(
                "hamvf\n", encoding="utf-8",
            )
            cfg = rp.Config(dut="imh", workarea=root)
            rc = rp.main(["--dut", "imh", "--workarea", str(root), "--dry-run"])
            self.assertEqual(rc, 0)
            self.assertFalse(cfg.summary.exists())
            self.assertFalse(cfg.compute_csv.exists())

    def test_main_full_run_writes_all_five_reports(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_valid_workarea(root)
            (root / "power" / "pprtl2" / "prep_pprtl2_partition.list").write_text(
                "ghost_module\n", encoding="utf-8",
            )
            cfg = rp.Config(dut="imh", workarea=root)
            rc = rp.main(["--dut", "imh", "--workarea", str(root)])
            self.assertEqual(rc, 0)
            for p in (cfg.summary, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.readme):
                self.assertTrue(p.exists(), f"{p} was not written")
            self.assertIn("ghost_module", cfg.compute_csv.read_text(encoding="utf-8"))


class TestGenerateReports(unittest.TestCase):
    """§7 test plan item 6 — generate_reports() glue: builds rows once and writes all 5 output files."""

    def test_writes_all_five_files_with_command_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "output" / "imh" / "pprtl2").mkdir(parents=True)
            (root / "power" / "pprtl2").mkdir(parents=True)
            (root / "power" / "pprtl2" / "prep_pprtl2_partition.list").write_text(
                "ghost_module\n", encoding="utf-8",
            )
            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen, module_status = rp.generate_reports(cfg, "report_pprtl2.py --dut imh")

            self.assertEqual(len(rows), 1)
            self.assertIn("Command Line: report_pprtl2.py --dut imh", cfg.summary.read_text(encoding="utf-8"))
            for p in (cfg.summary, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.readme):
                self.assertTrue(p.exists())


class TestCsvAndReportWriters(unittest.TestCase):
    """§7 test plan item 6 — report generation writes the expected files/columns."""

    def test_compute_and_qor_csv_headers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            out_root = root / "power" / "pprtl2"
            out_root.mkdir(parents=True)
            cfg = rp.Config(dut="imh", workarea=root)

            row = rp.Row(
                module="hamvf", power_mode="vectorless", test_name="", instance="",
                elab=rp.StageResult("Pass", 100.0, 1.0),
                fsdb=rp.StageResult("Not Required", None, None),
                power=rp.StageResult("Pass", 50.0, 2.0),
                qor={
                    "cell_count": 100, "combinational_cell_count": 60,
                    "register_cell_count": 10, "unclocked_sequential_cell_count": 2,
                    "register_bit_count": 20, "untraced_sequentials_percentage": 16.67,
                    "CGR": 90.0, "CGE": 80.0, "DACGE": 85.0,
                    "flop_cell_count": 5, "mbflop_cell_count": 1, "eqfb": 30,
                    "latch_cell_count": 0, "mblatch_cell_count": 0, "eqlb": 0,
                    "VCS_VERSION": "X-2025.06-SP2-3_Full64",
                    "VERDI_VERSION": "X-2025.06-SP2",
                    "PPRTL_VERSION": "X-2025.06-SP3-20260214",
                },
            )
            rp.write_compute_csv(cfg, [row])
            rp.write_qor_csv(cfg, [row])

            compute_text = cfg.compute_csv.read_text(encoding="utf-8")
            self.assertIn("module,power_mode,test_name,instance", compute_text.splitlines()[0])
            self.assertIn("hamvf,vectorless,,,Pass,Not Required,Pass,100", compute_text)

            qor_text = cfg.qor_csv.read_text(encoding="utf-8")
            self.assertIn(
                "untraced_sequentials_percentage,annotation_primary_io,annotation_bb,annotation_seq,CGR,CGE,DACGE",
                qor_text.splitlines()[0],
            )
            self.assertIn("combinational_cell_count,unclocked_sequential_cell_count", qor_text.splitlines()[0])
            self.assertIn("VCS_VERSION,VERDI_VERSION,PPRTL_VERSION", qor_text.splitlines()[0])
            self.assertIn("X-2025.06-SP2-3_Full64,X-2025.06-SP2,X-2025.06-SP3-20260214", qor_text)

    def test_readme_md_is_static(self) -> None:
        self.assertTrue(rp.README_MD.startswith("# report_pprtl2.README\n"))
        self.assertIn("Clock Gating Ratio (CGR)", rp.README_MD)
        self.assertIn("DACGE", rp.README_MD)
        self.assertIn("report_rtl_metrics -list_attributes -view", rp.README_MD)
        self.assertIn("EQFB", rp.README_MD)
        self.assertIn("EQLB", rp.README_MD)

    def test_fail_details_no_matches_found(self) -> None:
        row = rp.Row(
            module="parx", power_mode="vectorless", test_name="", instance="",
            elab=rp.StageResult("Pass", None, None),
            fsdb=rp.StageResult("Not Required", None, None),
            power=rp.StageResult("Fail=2", None, None),
        )
        text = rp.render_fail_details([row])
        self.assertIn("Partition: parx", text)
        self.assertIn("No matches found", text)

    def test_fail_details_no_grep_pattern_header(self) -> None:
        row = rp.Row(
            module="parx", power_mode="vectorless", test_name="", instance="",
            elab=rp.StageResult("Pass", None, None),
            fsdb=rp.StageResult("Not Required", None, None),
            power=rp.StageResult("Fail=2", None, None),
        )
        text = rp.render_fail_details([row])
        self.assertNotIn("Grep Pattern", text)
        self.assertEqual(text.splitlines()[0], "Partition: parx")

    def test_fail_details_includes_read_sdc_log(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            read_sdc_log = Path(tmp) / "read_sdc.log"
            read_sdc_log.write_text("line0\nError: bad sdc\nline2\nline3\nline4\nline5\n", encoding="utf-8")
            row = rp.Row(
                module="parx", power_mode="vectorless", test_name="", instance="",
                elab=rp.StageResult("Pass", None, None),
                fsdb=rp.StageResult("Not Required", None, None),
                power=rp.StageResult("Fail=2", None, None),
                read_sdc_log=read_sdc_log,
            )
            text = rp.render_fail_details([row])
            self.assertIn(f"Log: {read_sdc_log}", text)
            self.assertIn("Error: bad sdc", text)


class TestGrepContextBlocks(unittest.TestCase):
    """§7 test plan item 1 / spec section 3.6 — 1 line before / 3 lines after each match."""

    def test_single_match_window(self) -> None:
        text = "\n".join([
            "line0", "line1", "Error: bad thing happened", "line3", "line4", "line5", "line6",
        ])
        blocks = rp.grep_context_blocks(text)
        self.assertEqual(blocks, ["line1", "Error: bad thing happened", "line3", "line4", "line5"])

    def test_no_matches(self) -> None:
        self.assertEqual(rp.grep_context_blocks("nothing here\nall clear\n"), [])

    def test_multiple_distant_matches_are_separated(self) -> None:
        lines = [f"line{i}" for i in range(20)]
        lines[2] = "Error: first"
        lines[15] = "Error-second"
        blocks = rp.grep_context_blocks("\n".join(lines))
        self.assertIn("...", blocks)
        self.assertIn("Error: first", blocks)
        self.assertIn("Error-second", blocks)

    def test_adjacent_matches_merge_into_one_window(self) -> None:
        text = "\n".join(["l0", "Error: one", "Error: two", "l3", "l4", "l5"])
        blocks = rp.grep_context_blocks(text)
        self.assertNotIn("...", blocks)
        self.assertEqual(blocks, ["l0", "Error: one", "Error: two", "l3", "l4", "l5"])

    def test_bracket_error_alternation_matches(self) -> None:
        text = "\n".join(["l0", "[ERROR] something broke", "l2", "l3", "l4", "l5"])
        blocks = rp.grep_context_blocks(text)
        self.assertIn("[ERROR] something broke", blocks)


class TestSymlinkTarget(unittest.TestCase):
    """§7 test plan item 1 / spec section 3.3 — REF_MODEL/SDC_ARCHIVE must print the symlink TARGET."""

    def test_resolves_to_symlink_target(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            real_target = tmp_path / "real_target_dir"
            real_target.mkdir()
            link = tmp_path / "REF_MODEL"
            link.symlink_to(real_target)
            self.assertEqual(rp.symlink_target(link), str(real_target.resolve()))

    def test_na_when_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(rp.symlink_target(Path(tmp) / "nope"), "NA")


class TestRenderSummaryMd(unittest.TestCase):
    """§7 test plan item 6 / spec section 3.3 — new elab:/vectorless:/timebased:
    pass/fail/running/not-started structure, MTL_FILE, count+percent pairs."""

    def _cfg(self, tmp: Path) -> rp.Config:
        (tmp / "power" / "pprtl2").mkdir(parents=True)
        return rp.Config(dut="imh", workarea=tmp)

    def test_command_line_and_new_status_sections(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            cfg = self._cfg(tmp_path)
            cfg.report_summary.write_text("total partitions : 2\n", encoding="utf-8")

            rows = [
                rp.Row(
                    module="hamvf", power_mode="vectorless", test_name="", instance="",
                    elab=rp.StageResult("Pass", None, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Pass", None, None),
                ),
                rp.Row(
                    module="parx", power_mode="vectorless", test_name="", instance="",
                    elab=rp.StageResult("Fail=2", None, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Not Started", None, None),
                ),
            ]
            module_status = {
                "hamvf": rp.ModuleStatus(
                    elab=rp.StageResult("Pass", None, None),
                    vectorless_power=rp.StageResult("Pass", None, None),
                    fsdb=None, timebased_power=None,
                ),
                "parx": rp.ModuleStatus(
                    elab=rp.StageResult("Fail=2", None, None),
                    vectorless_power=rp.StageResult("Not Started", None, None),
                    fsdb=None, timebased_power=None,
                ),
            }
            text = rp.render_summary_md(
                cfg, rows, {}, module_status, "report_pprtl2.py --dut imh --workarea /wa",
            )

            self.assertEqual(text.splitlines()[0], "Command Line: report_pprtl2.py --dut imh --workarea /wa")
            self.assertIn("MTL_FILE: NA", text)
            self.assertIn("total partitions 2", text)
            self.assertNotIn("pre-flight", text)

            self.assertIn("elab:", text)
            self.assertIn("total partitions pass elab: 1  50.0%", text)
            self.assertIn("total partitions fail elab:  1  50.0%", text)
            self.assertIn("total partitions still running elab:  0  0.0%", text)
            self.assertIn("total partitions not started elab:  0  0.0%", text)

            self.assertIn("vectorless:", text)
            self.assertIn("total partitions pass vectorless power: 1  50.0%", text)
            self.assertIn("total partitions not started vectorless power:  1  50.0%", text)

            self.assertIn("timebased:", text)
            self.assertIn("total partitions that executed greater than one testname: 0", text)
            self.assertIn("No Partitions Executed Greater Than One Test", text)

    def test_fsdb_and_timebased_power_use_timebased_denominator(self) -> None:
        """fsdb/timebased power sections must use the timebased-target count
        (e.g. 143) as denominator, not the full vectorless/elab count (146)."""
        with tempfile.TemporaryDirectory() as tmp:
            cfg = self._cfg(Path(tmp))
            module_status = {
                "vec_only": rp.ModuleStatus(
                    elab=rp.StageResult("Pass", None, None),
                    vectorless_power=rp.StageResult("Pass", None, None),
                    fsdb=None, timebased_power=None,
                ),
                "both": rp.ModuleStatus(
                    elab=rp.StageResult("Pass", None, None),
                    vectorless_power=rp.StageResult("Pass", None, None),
                    fsdb=rp.StageResult("Pass", None, None),
                    timebased_power=rp.StageResult("Pass", None, None),
                ),
            }
            text = rp.render_summary_md(cfg, [], {}, module_status, "")
            # fsdb/timebased power denominator is 1 (only "both" is a timebased target)
            self.assertIn("total partitions pass fsdb: 1  100.0%", text)
            self.assertIn("total partitions pass timebased power: 1  100.0%", text)
            # elab/vectorless denominator is 2 (both modules)
            self.assertIn("total partitions pass elab: 2  100.0%", text)
            self.assertIn("total partitions pass vectorless power: 2  100.0%", text)

    def test_multi_test_partitions_listed_when_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            cfg = self._cfg(tmp_path)
            rows = [
                rp.Row(
                    module="d2d1", power_mode="timebased", test_name="test_a", instance="i1",
                    elab=rp.StageResult("Pass", None, None), fsdb=rp.StageResult("Pass", None, None),
                    power=rp.StageResult("Pass", None, None),
                ),
                rp.Row(
                    module="d2d1", power_mode="timebased", test_name="test_b", instance="i1",
                    elab=rp.StageResult("Pass", None, None), fsdb=rp.StageResult("Pass", None, None),
                    power=rp.StageResult("Pass", None, None),
                ),
            ]
            module_status = {
                "d2d1": rp.ModuleStatus(
                    elab=rp.StageResult("Pass", None, None), vectorless_power=None,
                    fsdb=rp.StageResult("Pass", None, None),
                    timebased_power=rp.StageResult("Pass", None, None),
                ),
            }
            text = rp.render_summary_md(cfg, rows, {}, module_status, "")
            self.assertIn("total partitions that executed greater than one testname: 1", text)
            self.assertIn("d2d1", text.splitlines()[-1])
            self.assertNotIn("No Partitions Executed Greater Than One Test", text)

    def test_runtime_stats_no_passing_runs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cfg = self._cfg(Path(tmp))
            rows = [
                rp.Row(
                    module="hamvf", power_mode="vectorless", test_name="default", instance="",
                    elab=rp.StageResult("Pass", None, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Fail=2", None, None),
                ),
            ]
            text = rp.render_summary_md(cfg, rows, {}, {}, "")
            self.assertIn("No runtime datapoints for timebased power (no passing runs)", text)
            self.assertIn("No runtime datapoints for vectorless power (no passing runs)", text)

    def test_runtime_stats_count_mean_and_fastest_slowest(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cfg = self._cfg(Path(tmp))
            # 6 vectorless partitions, runtimes 10..60 seconds -- exercises top-5/bottom-5 truncation.
            rows = [
                rp.Row(
                    module=f"par{i}", power_mode="vectorless", test_name="default", instance="",
                    elab=rp.StageResult("Pass", 10.0 * i, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Pass", 0.0, None),
                )
                for i in range(1, 7)
            ]
            # d2d1: two timebased test rows sharing the same module-level runtime -- must be deduped.
            rows += [
                rp.Row(
                    module="d2d1", power_mode="timebased", test_name=t, instance="i1",
                    elab=rp.StageResult("Pass", 5.0, None),
                    fsdb=rp.StageResult("Pass", 3.0, None),
                    power=rp.StageResult("Pass", 2.0, None),
                )
                for t in ("test_a", "test_b")
            ]
            text = rp.render_summary_md(cfg, rows, {}, {}, "")

            self.assertIn("number of partitions passing timebased power: 1", text)
            self.assertIn("mean total runtime all partitions passing timebased power: 00d:00h:00m:10s", text)
            self.assertIn("number of partitions passing vectorless power: 6", text)
            # mean of 10+20+...+60 = 35 seconds
            self.assertIn("mean total runtime all partitions passing vectorless power: 00d:00h:00m:35s", text)

            fastest_idx = text.index("Top 5 fastest partitions with passing vectorless power runs:")
            slowest_idx = text.index("Bottom 5 slowest partitions with passing vectorless power runs:")
            fastest_block = text[fastest_idx:slowest_idx]
            self.assertIn("00d:00h:00m:10s  par1", fastest_block)
            self.assertIn("00d:00h:00m:50s  par5", fastest_block)  # 5th fastest of 6
            self.assertNotIn("par6", fastest_block)

            slowest_block = text[slowest_idx:]
            self.assertIn("00d:00h:01m:00s  par6", slowest_block)
            self.assertIn("00d:00h:00m:20s  par2", slowest_block)  # 5th slowest of 6
            self.assertNotIn("par1\n", slowest_block)
            # ascending order within the bottom-5 block too (par2 before par6)
            self.assertLess(slowest_block.index("par2"), slowest_block.index("par6"))

    def test_mtl_file_shows_resolved_symlink_target(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            cfg = self._cfg(tmp_path)
            real_target = tmp_path / "mtl_target.mtl"
            real_target.write_text("mtl", encoding="utf-8")
            cfg.mtl_file.symlink_to(real_target)
            text = rp.render_summary_md(cfg, [], {}, {}, "")
            self.assertIn(f"MTL_FILE: {real_target.resolve()}", text)

    def test_action_required_lists_named_partitions_with_log_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            cfg = self._cfg(tmp_path)
            module_status = {
                "good": rp.ModuleStatus(
                    elab=rp.StageResult("Pass", None, None),
                    vectorless_power=rp.StageResult("Pass", None, None),
                    fsdb=None, timebased_power=None,
                ),
                "broken": rp.ModuleStatus(
                    elab=rp.StageResult("Fail=2", None, None),
                    vectorless_power=rp.StageResult("Not Started", None, None),
                    fsdb=None, timebased_power=None,
                ),
                "inflight": rp.ModuleStatus(
                    elab=rp.StageResult("Running", None, None),
                    vectorless_power=None, fsdb=None, timebased_power=None,
                ),
            }
            text = rp.render_summary_md(cfg, [], {}, module_status, "")

            expected_log = rp.grdlbuild_log_path(tmp_path, "broken", "elab")
            self.assertIn("Partitions that fail elab:", text)
            self.assertIn(f"broken  {expected_log}", text)
            self.assertIn("Partitions that are still running elab:", text)
            self.assertIn("inflight", text)
            self.assertIn("Partitions that have not started elab:", text)
            self.assertIn("No partitions have not started elab", text)
            self.assertIn("Partitions that fail vectorless power:", text)
            self.assertIn("No partitions failed vectorless power", text)
            self.assertIn("Partitions that have not started vectorless power:", text)
            self.assertIn("broken", text)


    def test_no_top_ip_name_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cfg = self._cfg(Path(tmp))
            text = rp.render_summary_md(cfg, [], {}, {}, "")
            self.assertNotIn("TOP_IP_NAME", text)

    def test_grdlbuild_and_flow_log_coverage_lines(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            cfg = self._cfg(tmp_path)
            cfg.report_summary.write_text("total partitions : 2\n", encoding="utf-8")

            # hamvf: has a real elab flow.log on disk -> counts for flow-log coverage.
            elab_flow_log = tmp_path / "output" / "imh" / "pprtl2" / "hamvf_pass01" / "elab" / "log" / "flow.log"
            elab_flow_log.parent.mkdir(parents=True)
            elab_flow_log.write_text("some content", encoding="utf-8")

            # parx: has a grdlbuild elab log on disk -> counts for grdlbuild coverage.
            grdl_log = rp.grdlbuild_log_path(tmp_path, "parx", "elab")
            grdl_log.parent.mkdir(parents=True)
            grdl_log.write_text("some content", encoding="utf-8")

            rows = [
                rp.Row(
                    module="hamvf", power_mode="vectorless", test_name="", instance="",
                    elab=rp.StageResult("Pass", None, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Pass", None, None),
                    elab_flow_log=elab_flow_log,
                ),
                rp.Row(
                    module="parx", power_mode="vectorless", test_name="", instance="",
                    elab=rp.StageResult("Fail=2", None, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Not Started", None, None),
                    elab_grdl_log=grdl_log,
                ),
            ]
            module_status = {
                "hamvf": rp.ModuleStatus(
                    elab=rp.StageResult("Pass", None, None),
                    vectorless_power=rp.StageResult("Pass", None, None),
                    fsdb=None, timebased_power=None,
                ),
                "parx": rp.ModuleStatus(
                    elab=rp.StageResult("Fail=2", None, None),
                    vectorless_power=rp.StageResult("Not Started", None, None),
                    fsdb=None, timebased_power=None,
                ),
            }
            text = rp.render_summary_md(cfg, rows, {}, module_status, "")
            self.assertIn("total partitions with at least one grdlbuild log: 1  50.0%", text)
            self.assertIn("total partitions with at least one stage flow.log file: 1  50.0%", text)


if __name__ == "__main__":
    unittest.main()
