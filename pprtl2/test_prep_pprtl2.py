#!/usr/bin/env python3
"""Unit tests for prep_pprtl2 (spec test plan tests 1-4).

Run:  python3 -m unittest scripts.pprtl2.test_prep_pprtl2  -v
  or: python3 scripts/pprtl2/test_prep_pprtl2.py
"""

from __future__ import annotations

import csv
import subprocess
import tempfile
import unittest
from pathlib import Path

import prep_pprtl2 as pp


def _fake_minimize(scripts_dir, ref_hip, out_dir):  # noqa: ANN001
    (out_dir / "hip.ldb.list.minimized").write_text(
        "#HIPS_MISSING_LDB_OR_LIB_COUNT: 0\n", encoding="utf-8"
    )
    return subprocess.CompletedProcess([], 0, "", "")


def _fake_minimize_fail(scripts_dir, ref_hip, out_dir):  # noqa: ANN001
    (out_dir / "hip.ldb.list.minimized").write_text(
        "#HIPS_MISSING_LDB_OR_LIB_COUNT: 2\n", encoding="utf-8"
    )
    return subprocess.CompletedProcess([], 0, "", "")


def _fake_fixclocks(scripts_dir, partition, rel_dir, cwd):  # noqa: ANN001
    (cwd / f"{partition}_clocks.tcl.fixclocks").write_text("FIX\n", encoding="utf-8")
    return subprocess.CompletedProcess([], 0, "", "")


BLOCKS_CFG_FIXTURE = """\
#==============================================================================
# File created by : show_nlib_info
#==============================================================================

## ALL Pars

[paraccasf]
block_type = partition
hier_type = part
children =

[paracccpc]
hier_type = part
block_type = partition

# a fullchip block (hier_type top -> excluded)
[some_fullchip]
block_type = fc
hier_type = top

#[parsocsouth0chassis]
#block_type = partition
#hier_type = part

[paracchap]
hier_type = part
"""


class TestParsePartitions(unittest.TestCase):
    """Spec test 1 — partition parsing."""

    def test_only_partition_blocks_returned_in_order(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp) / "imh.blocks.cfg"
            cfg.write_text(BLOCKS_CFG_FIXTURE, encoding="utf-8")
            self.assertEqual(
                pp.parse_partitions(cfg),
                ["paraccasf", "paracccpc", "paracchap"],
            )

    def test_fallback_to_block_type_when_no_hier_type(self) -> None:
        # ioh/cbb0-style: no hier_type field anywhere => block_type = partition
        # AND name starts with "par". Non-"par" partitions are excluded.
        fixture = (
            "[par_acc]\nblock_type = partition\n\n"
            "[acc]\nblock_type = partition\n\n"  # not par-prefixed -> excluded
            "[some_fc]\nblock_type = fc\n\n"
            "#[commented_part]\n#block_type = partition\n\n"
            "[par_acc2]\nblock_type = partition\n"
        )
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp) / "ioh.blocks.cfg"
            cfg.write_text(fixture, encoding="utf-8")
            self.assertEqual(pp.parse_partitions(cfg), ["par_acc", "par_acc2"])

    def test_missing_file_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(FileNotFoundError):
                pp.parse_partitions(Path(tmp) / "nope.blocks.cfg")


class TestPathDerivation(unittest.TestCase):
    """Spec test 2 — path derivation."""

    def _cfg(self, dut: str = "imh") -> pp.Config:
        return pp.Config(
            dut=dut,
            workarea=Path("/wa"),
            ref_model=Path("/wa/power/pprtl2/REF_MODEL"),
            sdc_archive=Path("/wa/power/pprtl2/SDC_ARCHIVE"),
            templates=Path("/repo/scripts/pprtl2/cor"),
            profile=pp.DIE_PROFILES[dut],
            partitions=None,
        )

    def test_config_derived_paths(self) -> None:
        cfg = self._cfg()
        self.assertEqual(cfg.out_root, Path("/wa/power/pprtl2"))
        self.assertEqual(cfg.blocks_cfg, Path("/wa/partition/imh.blocks.cfg"))
        self.assertEqual(cfg.report_csv, Path("/wa/power/pprtl2/prep_pprtl2_report.csv"))
        self.assertEqual(cfg.report_summary, Path("/wa/power/pprtl2/prep_pprtl2_report.summary"))

    def test_blocks_cfg_per_die_and_override(self) -> None:
        self.assertEqual(self._cfg("cbb0").blocks_cfg, Path("/wa/partition/cbb0_h2b.blocks.cfg"))
        cfg = pp.Config(
            dut="cbb0",
            workarea=Path("/wa"),
            ref_model=Path("/wa/power/pprtl2/REF_MODEL"),
            sdc_archive=Path("/wa/power/pprtl2/SDC_ARCHIVE"),
            templates=Path("/repo/scripts/pprtl2/cor"),
            profile=pp.DIE_PROFILES["cbb0"],
            partitions=None,
            blocks_cfg_override=Path("/custom/list.blocks.cfg"),
        )
        self.assertEqual(cfg.blocks_cfg, Path("/custom/list.blocks.cfg"))

    def test_partition_paths_with_release(self) -> None:
        cfg = self._cfg()
        p = pp.derive_partition_paths(cfg, "paracccpc", "CORIMH_H2B_0P0", "trial")

        ref_base = Path("/wa/power/pprtl2/REF_MODEL/output/imh/partition/paracccpc/h2b/trial")
        self.assertEqual(p.ref_2stage, ref_base / "fe_collateral" / "rtl_list_2stage.tcl")
        self.assertEqual(p.ref_hip, ref_base / "hip_collaterals" / "hip.ldb.list")

        rel_dir = Path("/wa/power/pprtl2/SDC_ARCHIVE/paracccpc/clock_collateral/CORIMH_H2B_0P0")
        self.assertEqual(p.clock_release_dir, rel_dir)
        self.assertEqual(p.clock_tcl, rel_dir / "paracccpc_clocks.tcl")

        out = Path("/wa/power/pprtl2/partition/paracccpc")
        self.assertEqual(p.part_out_dir, out)
        self.assertEqual(p.flow_cfg, Path("/wa/power/pprtl2/partition/paracccpc.flow.cfg"))
        self.assertEqual(p.hip_minimized, out / "hip.ldb.list.minimized")
        self.assertEqual(p.clocks_fixclocks, out / "paracccpc_clocks.tcl.fixclocks")
        self.assertEqual(p.elab_pre_tcl, out / "elab.pre.tcl")

    def test_partition_paths_without_release(self) -> None:
        cfg = self._cfg()
        p = pp.derive_partition_paths(cfg, "paracccpc", None, "trial")
        self.assertIsNone(p.clock_release)
        self.assertIsNone(p.clock_release_dir)
        self.assertIsNone(p.clock_tcl)
        # ref + output paths are still derivable
        self.assertTrue(str(p.ref_2stage).endswith("h2b/trial/fe_collateral/rtl_list_2stage.tcl"))

    def test_partition_paths_h2b_subdir_variants(self) -> None:
        cfg = self._cfg("cbb0")
        # cbb0-style sublevel
        p = pp.derive_partition_paths(cfg, "par_base_sbo", None, "cbb0")
        self.assertTrue(str(p.ref_2stage).endswith("h2b/cbb0/fe_collateral/rtl_list_2stage.tcl"))
        self.assertTrue(str(p.ref_hip).endswith("h2b/cbb0/hip_collaterals/hip.ldb.list"))
        # unresolved sublevel => ref paths are None, outputs still derivable
        p2 = pp.derive_partition_paths(cfg, "par_base_sbo", None, None)
        self.assertIsNone(p2.ref_2stage)
        self.assertIsNone(p2.ref_hip)
        self.assertEqual(
            p2.elab_pre_tcl, Path("/wa/power/pprtl2/partition/par_base_sbo/elab.pre.tcl")
        )

    def test_die_profiles(self) -> None:
        self.assertEqual(pp.DIE_PROFILES["ioh"].clock_release_prefix, "CORIOH")
        self.assertEqual(pp.DIE_PROFILES["ioh"].clock_release_token, "H2B")
        self.assertEqual(pp.DIE_PROFILES["cbb0"].clock_release_prefix, "CORCBBP")
        self.assertEqual(pp.DIE_PROFILES["cbb0"].clock_release_token, "CONTOUR")
        self.assertEqual(pp.DIE_PROFILES["imh"].blocks_cfg_name, "imh.blocks.cfg")
        self.assertEqual(pp.DIE_PROFILES["cbb0"].blocks_cfg_name, "cbb0_h2b.blocks.cfg")


class TestExecuteStaticOutputs(unittest.TestCase):
    """Spec test 3 (static copy) + test 4 (mocked generated collateral & report)."""

    def _setup(self, tmp: Path) -> pp.RunPlan:
        templates = tmp / "cor"
        templates.mkdir()
        (templates / "Makefile").write_text("MK\n", encoding="utf-8")
        (templates / "imh").mkdir()
        (templates / "imh" / "stdcell.ldb.list").write_text("STD-imh\n", encoding="utf-8")
        (templates / "tool.cth").write_text("CTH\n", encoding="utf-8")
        (templates / "activity_dir.map").write_text("ACT\n", encoding="utf-8")
        (templates / "partition.flow.cfg").write_text("FLOW\n", encoding="utf-8")
        (templates / "elab.pre.tcl").write_text("ELAB\n", encoding="utf-8")
        grdl = templates / "grdlbuild" / "power" / "partition_template"
        grdl.mkdir(parents=True)
        (grdl / "build.gradle.kts").write_text("GRDL\n", encoding="utf-8")
        (templates / "grdlbuild" / "settings.gradle.kts").write_text("SET\n", encoding="utf-8")
        (templates / "grdlbuild" / "gradle.properties").write_text(
            "outputDir=x\nblock = true\n", encoding="utf-8"
        )

        cfg = pp.Config(
            dut="imh",
            workarea=tmp / "wa",
            ref_model=tmp / "ref",
            sdc_archive=tmp / "sdc",
            templates=templates,
            profile=pp.DIE_PROFILES["imh"],
            partitions=None,
        )
        elig = pp.derive_partition_paths(cfg, "paracccpc", "REL", "trial")
        skip = pp.derive_partition_paths(cfg, "memtile", None, "trial")
        plan = pp.RunPlan(
            cfg=cfg,
            partitions=[
                pp.PartitionPlan(paths=elig, has_2stage=True, has_hip=True, has_clocks=True),
                pp.PartitionPlan(paths=skip, has_2stage=True, has_hip=True, has_clocks=False),
            ],
        )
        return plan

    def _run(self, plan: pp.RunPlan, force: bool = False) -> pp.ExecReport:
        return pp.execute_plan(
            plan, force=force, verbose=False, minimize=_fake_minimize, fixclocks=_fake_fixclocks
        )

    def test_static_and_flow_cfg_created(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            plan = self._setup(tmp)
            cfg = plan.cfg
            report = self._run(plan)

            # DUT-level static outputs, byte-identical to the die-specific templates
            self.assertEqual((cfg.out_root / "Makefile").read_text(), "MK\n")
            self.assertEqual((cfg.out_root / "stdcell.ldb.list").read_text(), "STD-imh\n")
            self.assertEqual((cfg.out_root / "tool.cth").read_text(), "CTH\n")
            self.assertEqual((cfg.out_root / "activity_dir.map").read_text(), "ACT\n")

            # grdlbuild copied verbatim (nested tree)
            self.assertEqual(
                (cfg.out_root / "grdlbuild" / "settings.gradle.kts").read_text(), "SET\n"
            )
            self.assertEqual(
                (cfg.out_root / "grdlbuild" / "power" / "partition_template"
                 / "build.gradle.kts").read_text(),
                "GRDL\n",
            )

            # eligible partition gets flow.cfg + elab.pre.tcl; skipped one does not
            part = cfg.out_root / "partition"
            self.assertEqual((part / "paracccpc.flow.cfg").read_text(), "FLOW\n")
            self.assertEqual((part / "paracccpc" / "elab.pre.tcl").read_text(), "ELAB\n")
            self.assertFalse((part / "memtile.flow.cfg").exists())
            # Makefile, stdcell, tool.cth, activity_dir.map, grdlbuild, flow.cfg, elab.pre.tcl
            self.assertEqual(len(report.outcome.created), 7)

    def test_generated_collateral_and_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            plan = self._setup(tmp)
            cfg = plan.cfg
            report = self._run(plan)

            pdir = cfg.out_root / "partition" / "paracccpc"
            self.assertEqual(
                (pdir / "hip.ldb.list.minimized").read_text(),
                "#HIPS_MISSING_LDB_OR_LIB_COUNT: 0\n",
            )
            self.assertEqual((pdir / "paracccpc_clocks.tcl.fixclocks").read_text(), "FIX\n")

            elig = next(r for r in report.results if r.partition == "paracccpc")
            self.assertTrue(
                elig.created_hip_minimized
                and elig.created_clocks_fixclocks
                and elig.created_elab_pre_tcl
            )
            self.assertFalse(elig.minimizehip_fail)

            # report CSV: header + one row per partition
            with cfg.report_csv.open(newline="") as fh:
                rows = list(csv.reader(fh))
            self.assertEqual(rows[0], pp.REPORT_COLUMNS)
            fidx = rows[0].index("minimizehip_fail")
            by_name = {r[0]: r for r in rows[1:]}
            self.assertEqual(by_name["paracccpc"][4], "REL")  # clock_release_used
            self.assertEqual(by_name["paracccpc"][5:8], ["yes", "yes", "yes"])
            self.assertEqual(by_name["paracccpc"][fidx], "no")
            self.assertEqual(by_name["memtile"][3], "no")  # clocks_tcl_exists
            self.assertEqual(by_name["memtile"][4], "N/A")
            self.assertEqual(by_name["memtile"][5:8], ["no", "no", "no"])
            self.assertEqual(by_name["memtile"][fidx], "N/A")

            summary = cfg.report_summary.read_text()
            self.assertRegex(summary, r"total partitions\s*:\s*2")
            self.assertRegex(summary, r"ran\s+:\s*1 \(50\.0%\)")
            self.assertRegex(summary, r"fail minimizehip\s+:\s*0")

            # prep_pprtl2_partition.list: only non-skipped partitions, one per line
            self.assertEqual(cfg.partition_list.name, "prep_pprtl2_partition.list")
            self.assertEqual(cfg.partition_list.read_text(), "paracccpc\n")

    def test_minimizehip_fail_disqualifies(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            plan = self._setup(tmp)
            cfg = plan.cfg
            report = pp.execute_plan(
                plan, force=False, verbose=False,
                minimize=_fake_minimize_fail, fixclocks=_fake_fixclocks,
            )
            elig = next(r for r in report.results if r.partition == "paracccpc")
            self.assertTrue(elig.minimizehip_fail)
            self.assertEqual(elig.hips_missing_ldb_count, 2)
            self.assertTrue(elig.created_hip_minimized)  # produced (evidence)
            self.assertFalse(elig.created_clocks_fixclocks)  # gated off
            self.assertFalse(elig.created_elab_pre_tcl)
            self.assertFalse((cfg.out_root / "partition" / "paracccpc" / "elab.pre.tcl").exists())

            # excluded from partition.list (not a clean run)
            self.assertEqual(cfg.partition_list.read_text(), "")

            summary = cfg.report_summary.read_text()
            self.assertRegex(summary, r"ran\s+:\s*0 \(0\.0%\)")
            self.assertRegex(summary, r"fail minimizehip\s+:\s*1")
            self.assertRegex(summary, r"\[fail minimizehip\] \(1\)\n  paracccpc")

            with cfg.report_csv.open(newline="") as fh:
                rows = list(csv.reader(fh))
            fidx = rows[0].index("minimizehip_fail")
            by_name = {r[0]: r for r in rows[1:]}
            self.assertEqual(by_name["paracccpc"][fidx], "yes")
            self.assertEqual(by_name["memtile"][fidx], "N/A")

    def test_idempotent_skip_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            plan = self._setup(tmp)
            self._run(plan)
            report2 = self._run(plan)
            self.assertEqual(len(report2.outcome.created), 0)
            self.assertIn(plan.cfg.out_root / "Makefile", report2.outcome.skipped_exist)

    def test_force_overwrites(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            plan = self._setup(tmp)
            self._run(plan)
            (plan.cfg.templates / "Makefile").write_text("MK2\n", encoding="utf-8")
            report2 = self._run(plan, force=True)
            self.assertEqual((plan.cfg.out_root / "Makefile").read_text(), "MK2\n")
            self.assertIn(plan.cfg.out_root / "Makefile", report2.outcome.overwritten)

    def test_grdlbuild_copied_verbatim(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            plan = self._setup(tmp)
            gp = plan.cfg.out_root / "grdlbuild" / "gradle.properties"
            self._run(plan)
            # copied exactly, with no dut stamp injected
            self.assertEqual(gp.read_text(), "outputDir=x\nblock = true\n")
            self.assertNotIn("dut=", gp.read_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
