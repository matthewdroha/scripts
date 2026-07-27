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

CELLS_RPT_FIXTURE = """\
Memory_cells: 0
Combinational_cells: 2593697
Sequential_cells: 47
Register_cells: 85560
BBox_cells: 0
Clock_newtwork_cells: 19325
Total_cells: 2750050
"""

POWER_GROUPS_RPT_FIXTURE = """\
****************************************
Report : report_power_groups
Design : hamvf
****************************************

Power Group                   Size     Attribute       
---------------------------------------------------
clock_network               19,325     Default         
register                    85,560     Default         
combinational            2,585,183     Default         
sequential                      47     Default         
memory                           0     Default         
io_pad                           0     Default         
black_box                        0     Default         
---------------------------------------------------
0
"""

CGE_HIER_RPT_FIXTURE = """\
****************************************
Report : report_rtl_metrics
****************************************

------------------------------------------------------------------
Register       Gated Register                                Instance
Bit Count      Bit Count        CGR (%)        CGE (%)        DACGE (%)      Name
------------------------------------------------------------------
245556         238584            97.16          64.78          75.45         hamvf
153443         149332            97.32          63.98          74.46         hamvf/mvfpar
"""

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
Maximum memory usage for this session: 9349076
Elapsed time for this session: 2047.17
##########################################################################
"""

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
    """§7 test plan item 1 — report-file parsing (cells/power_groups/cge.hier/stat2)."""

    def test_cells_rpt(self) -> None:
        kv = rp.parse_keyvalue_report(CELLS_RPT_FIXTURE)
        self.assertEqual(kv["Total_cells"], "2750050")
        self.assertEqual(kv["Register_cells"], "85560")
        self.assertEqual(kv["Sequential_cells"], "47")

    def test_power_groups_rpt(self) -> None:
        groups = rp.parse_power_groups(POWER_GROUPS_RPT_FIXTURE)
        self.assertEqual(groups["register"], 85560)
        self.assertEqual(groups["sequential"], 47)
        self.assertEqual(groups["clock_network"], 19325)
        self.assertEqual(groups["combinational"], 2585183)

    def test_cge_hier_module_row(self) -> None:
        row = rp.parse_cge_hier_module_row(CGE_HIER_RPT_FIXTURE, "hamvf")
        self.assertEqual(row["register_bit_count"], 245556)
        self.assertEqual(row["CGR"], 97.16)
        self.assertEqual(row["CGE"], 64.78)
        self.assertEqual(row["DACGE"], 75.45)

    def test_cge_hier_module_row_not_found(self) -> None:
        self.assertIsNone(rp.parse_cge_hier_module_row(CGE_HIER_RPT_FIXTURE, "nope"))

    def test_stat2_rpt(self) -> None:
        kv = rp.parse_keyvalue_report(STAT2_RPT_FIXTURE)
        self.assertEqual(kv["Total cell count"], "2106891")
        self.assertEqual(kv["Register Count"], "116488")
        self.assertEqual(kv["Sequential cells count"], "2882")
        self.assertEqual(kv["SCGE"], "99.26")
        self.assertEqual(kv["Untraced Sequential ratio"], "0.024143419619669933")


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
    """§7 test plan item 2 — per-stage Pass/Fail/Running/Not-Ran determination (no Skipped)."""

    def _write(self, path: Path, text: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def test_pass_via_marker_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            marker = tmp_path / "elab.PASS"
            marker.write_text("", encoding="utf-8")
            flow_log = tmp_path / "log" / "flow.log"
            self._write(flow_log, FLOW_LOG_FIXTURE)
            result = rp.evaluate_stage(pass_marker=marker, flow_log=flow_log, grdlbuild_log=None)
            self.assertEqual(result.status, "Pass")
            self.assertEqual(result.runtime_seconds, 10824.7)

    def test_fail_via_grdlbuild_exit_code_prefers_over_flow_log(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            marker = tmp_path / "power.PASS"  # absent
            flow_log = tmp_path / "log" / "flow.log"
            self._write(flow_log, FLOW_LOG_FIXTURE)
            grdl_log = tmp_path / "grdl.log"
            self._write(grdl_log, GRDLBUILD_FAIL_FOOTER_FIXTURE)
            result = rp.evaluate_stage(pass_marker=marker, flow_log=flow_log, grdlbuild_log=grdl_log)
            self.assertEqual(result.status, "Fail=2")

    def test_running_when_no_elapsed_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            marker = tmp_path / "elab.PASS"  # absent
            flow_log = tmp_path / "log" / "flow.log"
            self._write(flow_log, FLOW_LOG_RUNNING_FIXTURE)
            result = rp.evaluate_stage(pass_marker=marker, flow_log=flow_log, grdlbuild_log=None)
            self.assertEqual(result.status, "Running")

    def test_not_ran_when_no_logs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            result = rp.evaluate_stage(
                pass_marker=tmp_path / "elab.PASS", flow_log=tmp_path / "log" / "flow.log",
                grdlbuild_log=None,
            )
            self.assertEqual(result.status, "Not Ran")


class TestQorExtraction(unittest.TestCase):
    """§7 test plan item 3 — QoR precedence rules (S10-S18, stat2 precedence for timebased)."""

    def _write_reports(self, tmp: Path, module: str) -> Path:
        reports_dir = tmp / "reports"
        reports_dir.mkdir(parents=True)
        (reports_dir / f"{module}.cells.rpt").write_text(CELLS_RPT_FIXTURE, encoding="utf-8")
        (reports_dir / f"{module}.power_groups.rpt").write_text(POWER_GROUPS_RPT_FIXTURE, encoding="utf-8")
        (reports_dir / f"{module}.cge.hier.rpt").write_text(CGE_HIER_RPT_FIXTURE, encoding="utf-8")
        return reports_dir

    def test_vectorless_uses_cells_and_cge_hier(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            reports_dir = self._write_reports(Path(tmp), "hamvf")
            qor = rp.extract_qor_fields(reports_dir, "hamvf", "vectorless", None)
            self.assertEqual(qor["cell_count"], 2750050)
            self.assertEqual(qor["register_cell_count"], 85560)
            self.assertEqual(qor["sequential_cell_count"], 47)
            self.assertEqual(qor["register_bit_count"], 245556)
            self.assertEqual(qor["CGR"], 97.16)
            self.assertEqual(qor["CGE"], 64.78)
            self.assertEqual(qor["DACGE"], 75.45)
            # untraced = 47/(85560+47)*100
            self.assertAlmostEqual(qor["untraced_sequentials"], 0.05, places=2)

    def test_timebased_stat2_takes_precedence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            reports_dir = self._write_reports(tmp_path, "d2d1")
            stat2_path = reports_dir / "d2d1.stat2.rpt"
            stat2_path.write_text(STAT2_RPT_FIXTURE, encoding="utf-8")
            qor = rp.extract_qor_fields(reports_dir, "d2d1", "timebased", stat2_path)
            # stat2 values win over cells.rpt/cge.hier.rpt for timebased mode
            self.assertEqual(qor["cell_count"], 2106891)
            self.assertEqual(qor["register_cell_count"], 116488)
            self.assertEqual(qor["sequential_cell_count"], 2882)
            self.assertEqual(qor["CGR"], 99.26)
            self.assertEqual(qor["CGE"], 80.47)
            self.assertEqual(qor["DACGE"], 88.87)
            self.assertAlmostEqual(qor["untraced_sequentials"], 2.41, places=2)


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
            "| SKIP_STAGES |  | Default |\n"
            "+------+------+------+\n"
        )
        (flow_inputs / "config.log").write_text(config_text, encoding="utf-8")
        return pass_dir

    def test_vectorless_module_produces_one_row(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pass_dir = self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")

            elab_dir = pass_dir / "elab"
            (elab_dir).mkdir()
            (elab_dir / "elab.PASS").write_text("", encoding="utf-8")
            (elab_dir / "log").mkdir()
            (elab_dir / "log" / "flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")

            reports_dir = pass_dir / "power" / "vectorless" / "default" / "reports"
            reports_dir.mkdir(parents=True)
            (reports_dir / "hamvf.cells.rpt").write_text(CELLS_RPT_FIXTURE, encoding="utf-8")
            (reports_dir / "hamvf.cge.hier.rpt").write_text(CGE_HIER_RPT_FIXTURE, encoding="utf-8")
            power_default = pass_dir / "power" / "vectorless" / "default"
            (power_default / "vectorless.PASS").write_text("", encoding="utf-8")
            (power_default / "log").mkdir()
            (power_default / "log" / "vectorless.flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            self.assertIn("hamvf", chosen)
            row = rows[0]
            self.assertEqual(row.power_mode, "vectorless")
            self.assertEqual(row.elab.status, "Pass")
            self.assertEqual(row.power.status, "Pass")
            self.assertEqual(row.fsdb.status, "Not Required")
            self.assertEqual(row.qor["cell_count"], 2750050)

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
        never reached the power stage or was never discovered at all."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            elab_dir = root / "output" / "imh" / "pprtl2" / "hamvf_pass01" / "elab"
            elab_dir.mkdir()
            (elab_dir / "elab.PASS").write_text("", encoding="utf-8")
            (elab_dir / "log").mkdir()
            (elab_dir / "log" / "flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")
            power_default = root / "output" / "imh" / "pprtl2" / "hamvf_pass01" / "power" / "vectorless" / "default"
            power_default.mkdir(parents=True)
            (power_default / "vectorless.PASS").write_text("", encoding="utf-8")
            (power_default / "log").mkdir()
            (power_default / "log" / "vectorless.flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")

            out_root = root / "power" / "pprtl2"
            out_root.mkdir(parents=True)
            (out_root / "prep_pprtl2_partition.list").write_text(
                "hamvf\nghost_module\n", encoding="utf-8",
            )

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen = rp.build_rows(cfg)

            modules = {r.module for r in rows}
            self.assertEqual(modules, {"hamvf", "ghost_module"})
            self.assertNotIn("ghost_module", chosen)

            ghost_row = next(r for r in rows if r.module == "ghost_module")
            self.assertEqual(ghost_row.elab.status, "Not Ran")
            self.assertEqual(ghost_row.fsdb.status, "Not Ran")
            self.assertEqual(ghost_row.power.status, "Not Ran")
            self.assertEqual(ghost_row.power_mode, "")

    def test_elab_only_module_with_no_power_dir_yet_produces_fallback_row(self) -> None:
        """A module whose elab passed but whose power stage never started must
        still get a row (power_mode recovered from config.log), not zero rows."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "hamvf", "hamvf_pass01")
            elab_dir = root / "output" / "imh" / "pprtl2" / "hamvf_pass01" / "elab"
            elab_dir.mkdir()
            (elab_dir / "elab.PASS").write_text("", encoding="utf-8")
            (elab_dir / "log").mkdir()
            (elab_dir / "log" / "flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")
            # NB: no power/ dir at all -- power stage never started.

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            row = rows[0]
            self.assertEqual(row.module, "hamvf")
            self.assertEqual(row.elab.status, "Pass")
            self.assertEqual(row.fsdb.status, "Not Ran")
            self.assertEqual(row.power.status, "Not Ran")

    def test_elab_failed_module_with_no_power_dir_reports_fail_status(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_pass_dir(root, "imh", "parmiocxlrx_pcu", "parmiocxlrx_pcu_pass01")
            elab_dir = root / "output" / "imh" / "pprtl2" / "parmiocxlrx_pcu_pass01" / "elab"
            elab_dir.mkdir()
            # NB: no elab.PASS -- elab failed.
            (elab_dir / "log").mkdir()
            (elab_dir / "log" / "flow.log").write_text(FLOW_LOG_FIXTURE.replace(
                "elab stage passed successfully..", "elab stage failed",
            ), encoding="utf-8")

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen = rp.build_rows(cfg)

            self.assertEqual(len(rows), 1)
            row = rows[0]
            self.assertTrue(row.elab.status.startswith("Fail"))
            self.assertEqual(row.fsdb.status, "Not Ran")
            self.assertEqual(row.power.status, "Not Ran")

    def test_timebased_module_with_two_tests_produces_two_rows(self) -> None:
        """End-to-end (not just extract_qor_fields) coverage of the timebased
        test_name/instance discovery path, including fsdb evaluation."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pass_dir = self._make_pass_dir(root, "imh", "d2d1", "d2d1_pass01")

            elab_dir = pass_dir / "elab"
            elab_dir.mkdir()
            (elab_dir / "elab.PASS").write_text("", encoding="utf-8")
            (elab_dir / "log").mkdir()
            (elab_dir / "log" / "flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")

            for test_name in ("test_a", "test_b"):
                inst_dir = pass_dir / "power" / "timebased" / test_name / "d2d_1_d2d1"
                reports_dir = inst_dir / "reports"
                reports_dir.mkdir(parents=True)
                (reports_dir / "d2d1.stat2.rpt").write_text(STAT2_RPT_FIXTURE, encoding="utf-8")
                (reports_dir / "d2d1.cge.hier.rpt").write_text(
                    CGE_HIER_RPT_FIXTURE.replace("hamvf", "d2d1"), encoding="utf-8",
                )
                (inst_dir / "power.PASS").write_text("", encoding="utf-8")
                (inst_dir / "log").mkdir()
                (inst_dir / "log" / "timebased.flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")

                fsdb_dir = pass_dir / "fsdb" / test_name / "d2d_1_d2d1"
                fsdb_dir.mkdir(parents=True)
                (fsdb_dir / "fsdb.PASS").write_text("", encoding="utf-8")
                (fsdb_dir / "log").mkdir()
                (fsdb_dir / "log" / "flow.log").write_text(FLOW_LOG_FIXTURE, encoding="utf-8")

            cfg = rp.Config(dut="imh", workarea=root)
            rows, chosen = rp.build_rows(cfg)

            self.assertEqual(len(rows), 2)
            self.assertEqual({r.test_name for r in rows}, {"test_a", "test_b"})
            for r in rows:
                self.assertEqual(r.power_mode, "timebased")
                self.assertEqual(r.instance, "d2d_1_d2d1")
                self.assertEqual(r.elab.status, "Pass")
                self.assertEqual(r.fsdb.status, "Pass")
                self.assertEqual(r.power.status, "Pass")
                self.assertEqual(r.qor["cell_count"], 2106891)  # from stat2.rpt (precedence)


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
            self.assertFalse(cfg.summary_md.exists())
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
            for p in (cfg.summary_md, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.terminology_md):
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
            rows, chosen = rp.generate_reports(cfg, "report_pprtl2.py --dut imh")

            self.assertEqual(len(rows), 1)
            self.assertIn("Command Line: report_pprtl2.py --dut imh", cfg.summary_md.read_text(encoding="utf-8"))
            for p in (cfg.summary_md, cfg.compute_csv, cfg.qor_csv, cfg.fail_details, cfg.terminology_md):
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
                    "cell_count": 100, "register_cell_count": 10, "sequential_cell_count": 2,
                    "register_bit_count": 20, "untraced_sequentials": 16.67,
                    "CGR": 90.0, "CGE": 80.0, "DACGE": 85.0,
                },
            )
            rp.write_compute_csv(cfg, [row])
            rp.write_qor_csv(cfg, [row])

            compute_text = cfg.compute_csv.read_text(encoding="utf-8")
            self.assertIn("module,power_mode,test_name,instance", compute_text.splitlines()[0])
            self.assertIn("hamvf,vectorless,,,Pass,Not Required,Pass,100", compute_text)

            qor_text = cfg.qor_csv.read_text(encoding="utf-8")
            self.assertIn("register_bit_count,untraced_sequentials,CGR,CGE,DACGE", qor_text.splitlines()[0])

    def test_terminology_md_is_static(self) -> None:
        self.assertIn("Clock Gating Ratio (CGR)", rp.TERMINOLOGY_MD)
        self.assertIn("DACGE", rp.TERMINOLOGY_MD)

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
    """§7 test plan item 6 / spec section 3.3 — command line, count+percent pairs, no-multi-test note."""

    def _cfg(self, tmp: Path) -> rp.Config:
        (tmp / "power" / "pprtl2").mkdir(parents=True)
        return rp.Config(dut="imh", workarea=tmp)

    def test_command_line_and_counts_with_percentages(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            cfg = self._cfg(tmp_path)
            cfg.report_summary.write_text(
                "total partitions : 184\nran              : 181 (98.4%)\n", encoding="utf-8",
            )
            rows = [
                rp.Row(
                    module="hamvf", power_mode="vectorless", test_name="", instance="",
                    elab=rp.StageResult("Pass", None, None),
                    fsdb=rp.StageResult("Not Required", None, None),
                    power=rp.StageResult("Pass", None, None),
                ),
            ]
            chosen = {"hamvf": rp.PassCandidate(module="hamvf", pass_dir=tmp_path, mtime=0.0, config={"TOP_IP_NAME": "imh"})}
            text = rp.render_summary_md(cfg, rows, chosen, "report_pprtl2.py --dut imh --workarea /wa")

            self.assertEqual(text.splitlines()[0], "Command Line: report_pprtl2.py --dut imh --workarea /wa")
            self.assertIn("total partitions 184", text)
            self.assertIn("total partitions pass pre-flight 181  98.4%", text)
            self.assertIn("total partitions pass elab: 1  0.5%", text)
            self.assertIn("total partitions pass vectorless power: 1  0.5%", text)
            self.assertIn("total partitions pass elab: 0  0.0%", text)
            self.assertIn("total partitions that executed greater than one testname: 0", text)
            self.assertIn("No Partitions Executed Greater Than One Test", text)

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
            text = rp.render_summary_md(cfg, rows, {}, "")
            self.assertIn("total partitions that executed greater than one testname: 1", text)
            self.assertIn("d2d1", text.splitlines()[-1])
            self.assertNotIn("No Partitions Executed Greater Than One Test", text)

    def test_no_top_ip_name_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cfg = self._cfg(Path(tmp))
            text = rp.render_summary_md(cfg, [], {}, "")
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
                    module="parx", power_mode="", test_name="", instance="",
                    elab=rp.StageResult("Fail=2", None, None),
                    fsdb=rp.StageResult("Not Ran", None, None),
                    power=rp.StageResult("Not Ran", None, None),
                    elab_grdl_log=grdl_log,
                ),
            ]
            text = rp.render_summary_md(cfg, rows, {}, "")
            self.assertIn("total partitions with at least one grdlbuild log: 1  50.0%", text)
            self.assertIn("total partitions with at least one stage flow.log file: 1  50.0%", text)


if __name__ == "__main__":
    unittest.main()
