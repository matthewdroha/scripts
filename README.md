# scripts

A collection of utility scripts for automation, development workflows, and system administration.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
  - [Cloning the Repository](#cloning-the-repository)
- [Scripts](#scripts)
  - [coe75](#coe75)
  - [ctech](#ctech)
  - [dtswiki](#dtswiki)
  - [hsd](#hsd)
  - [ihdk](#ihdk)
  - [ivb](#ivb)
  - [pnr](#pnr)
  - [sip](#sip)
  - [skl](#skl)
  - [snb](#snb)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains scripts organized by purpose to help streamline common tasks. Scripts are written to be portable, well-documented, and easy to use.

Desired structure:  scripts/<activity>/<project>
<activity> can contain scripts
<project> may or may not exist and will contain scripts that are very specific to that project

In practice the collection is a large archive of Intel VLSI physical-design and CAD-flow automation, mostly Perl (with some csh, Tcl, and Perl module libraries). Content is grouped into top-level directories named for the CPU project or function they served (e.g. `ivb` for Ivy Bridge, `snb` for Sandy Bridge, `skl` for Skylake, `pnr` for place-and-route/migration). Within each project, work is further split into functional subdirectories that recur across projects:

| Subdir     | Role                                                             |
|------------|-----------------------------------------------------------------|
| `sch/`     | Schematic hierarchy tools and planning/profile reports          |
| `std/`     | Shared Perl module libraries (e.g. `DAStd.pm`, `Netbatch.pm`)   |
| `pdv/`     | Physical-design verification and result extraction              |
| `mig/`     | Layout/data migration toolkit                                   |
| `status/`  | Status and reporting jobs (often CSV/CGI output)                |
| `utils/`   | General-purpose helpers                                         |
| `cron/`    | Scheduled-job wrapper scripts                                   |
| `rv/`      | Reliability/voltage (RV) helpers                                |

## Usage

Each script is self-contained; run it directly with the appropriate interpreter (`perl`, `csh`, `tclsh`). Most Perl scripts expose usage via `--help`/`-h` or embedded POD (`perldoc <script>`).

### Cloning the Repository

1. HTTPS

    ```bash
    git clone https://github.com/matthewdroha/scripts.git
    ```

1. SSH

    ```bash
    git clone git@github.com:matthewdroha/scripts.git
    ```

1. GitHub CLI

    ```bash
    gh repo clone matthewdroha/scripts
    ```

## Scripts

The repository holds roughly 200 scripts across ~80 nested directories. Rather than list every file, this section summarizes each top-level project/category directory and its subdirectories.

### coe75

Schematic and standard-cell tooling for the COE 7.5 flow.

| Path            | Contents                                                                            |
|-----------------|-------------------------------------------------------------------------------------|
| `coe75/sch/`    | Schematic hierarchy tools: `sncells.pl`, `snprofile.pl` (generate/read `sn` files and produce hierarchy planning reports). |
| `coe75/status/` | Library/standard-cell status reporting: `libstat.pl`, `stdstat.pl`.                 |
| `coe75/std/`    | Shared Perl module libraries used by the COE 7.5 scripts.                           |
| `coe75/utils/`  | Helpers: `getma.pl`, `pbook.pl`, `pdlcheck.pl`, `redbooknames.pl`, `starter.pl` (script template). |

### ctech

Standard-cell / C-tech verification and cell-list generation.

| Path              | Contents                                                                          |
|-------------------|-----------------------------------------------------------------------------------|
| `ctech/`          | `check_stdcell_verilog.pl` — validates standard-cell Verilog, emits an XLSX report. |
| `ctech/mat164p0/` | Cell-list data (`n6.*.list`, `s14nm.*.list`) and `maket.csh`/`run.source` build drivers. |
| `ctech/mmg/`      | Per-node ctech/stdcell cell lists (`ctech.n5.h210.list`, etc.).                    |
| `ctech/nvlpcd/`   | NVLPCD cell lists and `genfile.ctech_exp.csv`.                                     |
| `ctech/unit/`     | `febe.source`, `simbuild.source` unit-build drivers.                              |

### dtswiki

Tooling to generate DTS wiki content from tool/technology release data.

| Path        | Contents                                                                                |
|-------------|-----------------------------------------------------------------------------------------|
| `dtswiki/`  | `build_toolver_csv.pl` (tool-version CSV builder), `git_log.pl`, `legacy_release_wikit.pl`, plus captured tool/tech history and latest `.txt` snapshots (e.g. `1813.18ww15g.*`). |
| `dtswiki/tsa_wiki_source/` | Versioned TSA wiki source trees (e.g. `1.05.02/p1273d1`).                 |

### hsd

Integration with HSD (Intel's defect/issue tracking system).

| Path         | Contents                                                                               |
|--------------|----------------------------------------------------------------------------------------|
| `hsd/ihdk/`  | HSD record access/update scripts via the `HSDFocus` API: `hsd.pl`, `hsd_read.pl`, `readHsd.pl`, `cdrfstart.pl`, `hsd_laymodule_move.pl`, `wip.pl`. |

### ihdk

IHDK project design-automation flows.

| Path              | Contents                                                                          |
|-------------------|-----------------------------------------------------------------------------------|
| `ihdk/db/`        | Data checks: `find_duplicate.pl`, `libstat.pl`.                                    |
| `ihdk/ec/`        | Engineering-change lint checks: `lintcsq.pl`, `lintdss.pl`, `lintnb.pl`.           |
| `ihdk/guardian/`  | Guardian-flow HSD scripts (mirror of `hsd/ihdk` plus `wip_old.pl`).               |
| `ihdk/nexus/`     | Tool-version and migration scans: `gettools.pl`, `getTCver.pl`, `migfullscan.pl`, `migshortscan.pl`, `inspect_irr_tarball.pl`, `threadcfg.pl`. |
| `ihdk/pdv/`       | Physical-design-verification extraction: `celllog2csv.pl`, `sum2csv.pl`.           |
| `ihdk/sp/`        | SPICE helper `spice2xl.pl` and supporting module.                                 |
| `ihdk/std/`       | Shared Perl module libraries.                                                     |
| `ihdk/utils/`     | Name/mail helpers: `idsid2mail.pl`, `redbooknames.pl`, `rundanames.pl`, `teamnames.pl`, `starter.pl`, plus `idsid.csv`/`idsid.txt` data. |

### ivb

Ivy Bridge project — the largest tree, covering schematic, verification, reporting, and data-integration flows.

| Path                  | Contents                                                                      |
|-----------------------|-------------------------------------------------------------------------------|
| `ivb/carmel/`         | `fakeleaf.pl` leaf-cell helper.                                               |
| `ivb/cellstudystat/`  | Cell-study statistics with `.csv` control/data files (`ctl/`).               |
| `ivb/cron/`           | Scheduled jobs: `cellstudy.csh`.                                              |
| `ivb/genesys/`        | Genesys tool integration: `rungenesys.pl`, `leaf2csv.pl`, `metric2csv.pl`, `macrosample.pl`, Tcl helpers (`mrSkl.tcl`, `mrUtils.tcl`, `fmrMig.tcl`). |
| `ivb/oracle/`         | Oracle/HSD access: `hsd.pl`, `readHsd.pl`, `vba.pl`, `wip.pl`, `cdrfstart.pl`. |
| `ivb/parade/`         | `paradecsv.pl` Parade data extraction.                                        |
| `ivb/pdv/`            | Physical-design verification: `runiss.pl`, `fanout.pl`, `grepsum.pl`, `grepdrcsum.pl`, `gradecmp.pl`, `mutate.pl`, `sum2csv.pl`, plus the bundled `HSDES_API` Perl library. |
| `ivb/rv/`             | Reliability/voltage: `rvmail.pl`, `sf.pl`, `sf2.pl` with `rv.list`/`pwrgrid.cfg`. |
| `ivb/sch/`            | Schematic tools: `grepinst.pl`, `grepnn.pl`, `mapiif.pl`, `snprofile.pl`, `purgedecaps.pl`, and Tcl helpers. |
| `ivb/status/`         | `cellstudystat.pl`, `libstat.pl` reporting.                                   |
| `ivb/std/`            | Shared Perl modules (`DAStd.pm`, `Logfile.pm`, `Netbatch.pm`, `UE.pm`).       |
| `ivb/utils/`          | Broad utilities: `ivbot.pl`, `nb.pl`, `laymodel.pl`, `lic_check.pl`, `sysMon.pl`, `mkfeed.pl`, `feedfails.pl`, `diff.pl`, and more. |

### pnr

Place-and-route and layout-migration flows (Penryn-era origins).

| Path          | Contents                                                                              |
|---------------|---------------------------------------------------------------------------------------|
| `pnr/cron/`   | Scheduled status runners: `cktstat_run.csh`, `laystat_run.csh`, `migstat_run.csh`, etc. |
| `pnr/dcc/`    | Decoupling-cap analysis: `dcc_histo.pl`, `dccf.pl`, `dccf_checkerboard.pl`.            |
| `pnr/mig/`    | Large migration toolkit (~60 scripts): `mig.pl`/`mig.tcl`, `premig.pl`/`postmig.pl`, `harvest.pl`, `drcstat.pl`, CGI reporters, plus `FilterTable.csv`/`Migration_Runset_Table.csv` and shared modules. |
| `pnr/pdv/`    | `get_bb_info.pl`, `pt.pl` verification helpers.                                        |
| `pnr/rv/`     | Reliability/voltage: `af.pl`, `rvinfo.pl`.                                             |
| `pnr/sch/`    | Schematic: `schdev.pl`, `sncount2.tcl`.                                                |
| `pnr/status/` | Prefill status reporting: `prefillstat.pl`, `prefillstatCGI.pl`.                       |
| `pnr/utils/`  | `checkec.pl`, `feedfails.pl`.                                                          |

### sip

System-in-Package (SIP) front-end/back-end and wiki flows.

| Path          | Contents                                                                              |
|---------------|---------------------------------------------------------------------------------------|
| `sip/fe/`     | Front-end compare: `compare_cust.pl` with `tools.list`.                                |
| `sip/febe/`   | FE/BE build/config: `makehip.pl`, `cellsingroup.pl`, `modify_rtl_list_2stage.pl`, plus `*.rdt_attributes.txt`/`versions.txt` data. |
| `sip/tsa/`    | Tool-version CSV builders: `build_toolver_csv.pl`, `build_toolver_csv_1410.pl`, `updatemat.pl`, with `headers.csv`. |
| `sip/utils/`  | `gtime_test.pl` timing helper.                                                         |
| `sip/wiki/`   | `git_log.pl` and wiki model data.                                                     |

### skl

Skylake project schematic and standard-cell tooling.

| Path          | Contents                                                                              |
|---------------|---------------------------------------------------------------------------------------|
| `skl/sch/`    | `iplan.pl` (iPlan backend), `sncells.pl`, `snprofile.pl`.                              |
| `skl/std/`    | Shared Perl module libraries.                                                          |
| `skl/utils/`  | `getma.pl`, `pbook.pl`, `pdlcheck.pl`, `redbooknames.pl`, `starter.pl`.                |

### snb

Sandy Bridge project flows.

| Path          | Contents                                                                              |
|---------------|---------------------------------------------------------------------------------------|
| `snb/env/`    | `mergefubs.pl` FUB-list merge helper.                                                  |
| `snb/parade/` | `paradecsv.pl` Parade extraction.                                                      |
| `snb/pdv/`    | `fanout.pl` verification helper and module.                                            |
| `snb/sch/`    | `schdev.pl`, `sncount2.tcl`.                                                           |
| `snb/std/`    | Shared Perl module libraries.                                                          |
| `snb/utils/`  | `laymodel.pl`.                                                                         |

## Requirements

- Perl (scripts pin various interpreter versions under `/usr/intel/pkgs/perl/...`)
- csh/tcsh for `*.csh` drivers and `tclsh` for `*.tcl` tools
- Intel-internal infrastructure for some scripts (HSD/`HSDFocus` API, Netbatch, `/nfs/site` paths)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-script`
3. Add your script with a usage message and inline documentation
4. Test your script thoroughly
5. Submit a pull request

## License

MIT
