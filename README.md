# scripts

A collection of utility scripts for automation, development workflows, and system administration.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
  - [Cloning the Repository](#cloning-the-repository)
- [Scripts](#scripts)
  - ctech
    - [check_stdcell_verilog.pl](#check_stdcell_verilogpl)
    - [maket.csh](#maketcsh)
  - dtswiki
    - [build_toolver_csv.pl](#build_toolver_csvpl)
    - [git_log.pl](#git_logpl)
    - [legacy_release_wikit.pl](#legacy_release_wikitpl)
  - hsd/ihdk
    - [cdrfstart.pl](#cdrfstartpl)
    - [hsd.pl](#hsdpl)
    - [hsd_laymodule_move.pl](#hsd_laymodule_movepl)
    - [hsd_read.pl](#hsd_readpl)
    - [readHsd.pl](#readhsdpl)
    - [wip.pl](#wippl)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)


## Overview

This repository contains scripts organized by purpose to help streamline common tasks. Scripts are written to be portable, well-documented, and easy to use.

Desired structure:  scripts/<activity>/<project>
<activity> can contain scripts
<project> may or may not exist and will contain scripts that are very specific to that project

The current contents are Intel VLSI physical-design / CAD-flow automation, mostly Perl with some tcsh. Three activities are present:

| Activity   | Purpose                                                                        |
|------------|--------------------------------------------------------------------------------|
| `ctech/`   | Standard-cell / C-tech Verilog checking and cell-list generation               |
| `dtswiki/` | Generating DTS wiki content (tables/CSV) from tool and technology release data |
| `hsd/`     | Querying and updating HSD (Intel's ticket/defect database) records             |

Each activity directory may contain project-specific subdirectories (e.g. `ctech/mat164p0/`, `ctech/mmg/`, `ctech/nvlpcd/` hold per-node cell lists; `hsd/ihdk/` holds the IHDK-project HSD scripts).

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

The repository currently holds 11 scripts across the `ctech`, `dtswiki`, and `hsd` activities. Each is summarized below. Generated outputs (`*.log`, `*.xlsx`, `*.wiki`) are produced by these scripts and are not documented as inputs.

### check_stdcell_verilog.pl

`ctech/check_stdcell_verilog.pl` — Reads an ordered list of Verilog `.v` files and checks that every cell reference is resolvable in the order called; an optional list of directories containing ctech `.sv` files can also be supplied. Key options: `--verilog-file-list`, `--ctech-dir-list`, `--udp`, `--check-sites`, `--run-name`, `--env 'VAR=VALUE'`, `--debug`, `--verbose`, `--help`. Writes an Excel (`.xlsx`) report and a `.log`. Input cell lists live alongside it under `ctech/mat164p0/`, `ctech/mmg/`, and `ctech/nvlpcd/` (`*.list` files).

### maket.csh

`ctech/mat164p0/maket.csh` — tcsh helper that runs `tpage` over each `*.ctech.*.t` template in the current directory, substituting `CTECH` and `CTECH_EXP` release paths, to generate the corresponding cell `.list` files.

### build_toolver_csv.pl

`dtswiki/build_toolver_csv.pl` — Builds a `.csv` tool-version summary for a given TSA version by loading baseline tool data and MAT tool-session hashes. Takes the TSA version (and an optional second argument) on the command line. Reads the TSA snapshot/session data under `dtswiki/tsa_wiki_source/<ver>/<project>/` (`ToolData.*.snap`, `tools.session.*`).

### git_log.pl

`dtswiki/git_log.pl` — Stdin filter that reads git-log lines and emits a tab-separated `Type<TAB>Date<TAB>Summary` table, classifying each entry as `Style`, `New`, `Improved`, `Fixed`, `Revert`, or `Unknown`.

### legacy_release_wikit.pl

`dtswiki/legacy_release_wikit.pl` — Converts a tab-separated release `.txt` table into a MediaWiki table, shading cells that change from the prior row. Runs `dos2unix` on the input first and writes `<input>.txt.wiki`. Consumes the captured `*.txt` release snapshots in `dtswiki/`.

### cdrfstart.pl

`hsd/ihdk/cdrfstart.pl` — Sets the `effort_category` field of an HSD record to `CDRF.Start` in tenant `hsd_mmg_physical_design` via the `HSDFocus` API. Takes the record ID as its single argument and prints the before/after value.

### hsd.pl

`hsd/ihdk/hsd.pl` — Updates an HSD record in tenant `hsd_mmg_physical_design`: sets `project` to `PNR` and rewrites `layout_module` (`pnrg.` → `pnr.`). Takes the record ID as its argument.

### hsd_laymodule_move.pl

`hsd/ihdk/hsd_laymodule_move.pl` — Sets the `ip_module` field of an HSD record in tenant `hsd_seg_ip` to a hard-coded target module. Takes the record ID as its argument.

### hsd_read.pl

`hsd/ihdk/hsd_read.pl` — Reads and prints the `status` field of an HSD record in tenant `hsd_seg_ip`. Takes the record ID as its argument (read-only).

### readHsd.pl

`hsd/ihdk/readHsd.pl` — Larger utility to query or modify the HSD layout-ticket database: it can list fields and records, and add records from CSV or XML input using a fixed set of ticket fields (`project`, `stepping`, `effort_category`, `title`, `layout_module`, `request_details`, `opus_sch_config`, `status`). Originally by Mike Farabee, updated by Matthew Roha for MMG/MIG.

### wip.pl

`hsd/ihdk/wip.pl` — Sets the `status` field of an HSD record to `WIP` in tenant `seg_ip`. Takes the record ID as its argument.

## Requirements

- Perl (scripts pin various interpreter versions under `/usr/intel/pkgs/perl/...`)
- tcsh for `*.csh` drivers; `tpage` (Template Toolkit) for `maket.csh`
- Intel-internal infrastructure for some scripts (HSD/`HSDFocus` API, `/nfs/site` and `/p/hdk` paths)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-script`
3. Add your script with a usage message and inline documentation
4. Test your script thoroughly
5. Submit a pull request

## License

MIT
