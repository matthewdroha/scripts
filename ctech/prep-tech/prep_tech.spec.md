# Spec: `prep_tech` — Cheetah process technology list files prep for ctech and synthesis

Status: **COMPLETE** — generation + 40 hermetic tests green; REGEX filters, contour library resolution, and `.cth` precedence landed (2026-07-20).  
Owner: mroha  
Language: **Python 3** (driver)  
Test framework: **pytest**  

---

## 1. Purpose

`prep_tech` prepares the Cheetah process technology list files for ctech and synthesis. It is a **generative, idempotent** workflow: re-running it reproduces the same output tree from the same inputs. It does **not** run the synthesis flow itself, nor does it modify any source files.

> **Using this document as a template.** This spec is structured so it can be reused for future automation. The reusable skeleton is: **Purpose → Inputs (sources of truth) → Path/resolution handling → Validation & dry-run → Outputs (generated tree + file formats) → Derivation/selection rules → Architecture & module responsibilities → CLI/usage → Testing → Resolved decisions**. Section 8 ("Reusable automation template") distills the generic pattern. Replace the domain-specific content of each section while keeping the section contract.

> **Terminology.** A **bundle** is a per-directory grouping under the stdcell library root (e.g. `base_lvt`, `clk_svt`) — a stdcell *function* combined with a threshold *variant* (`lvt`, `svt`, `hvt`, `ulvt`). Throughout this document, **bundle** = the directory; **variant** = the threshold flavor only.

---

## 2. Inputs (sources of truth)

| # | Source | Provides | Notes |
|---|--------|----------|-------|
| S1 | **prep_tech.input.md** — markdown file provided as input | Cheetah backend cheetah release containing needed .cth files; for each die listed contains ctech directories containing verilog and .cth files which contain the technology definition for stdcells used in ctech and ctech_exp verilog files |  |

The tech .cth files, for example 76p4_g1i_opt4.cth, contains the following interesting parameters in the [DESIGNPACKAGE] section:

lib_height_class  
lib_name  

<lib_name> will point to the stdcell library

example:  
i0m = designpackage(name=1278.6,path)/lib786_i0m_180h_50pp_pdk10_r8v2p0_fv

path  
version  

### 2.1 `prep_tech.input.md` format

- The `prep_tech.input.md` file remains **Markdown**, but its content is **machine-readable**.
- Sections are markdown headings:
  - `## Cheetah backend reference` — followed by a single vanity path to the Cheetah backend reference area (where `.cth` files live).
  - `## <NAME> DIE` — one section per die. The die's output directory name is `<NAME>` lowercased (e.g. `CORIMH DIE` → `corimh`).
- Within each die section:
  - A line whose **first token ends in `.cth`** is a **required** `.cth` filename (bare name). A die may list **one or many** `.cth` files; **all listed are required** (e.g. CORIMH needs both `g1i` and `g1m` to elaborate the reference stdcell instances inside the ctech verilog cells). The list of `.cth` files is mutually exclusive,  i.e. a definition of a standard cell needs to be unique per `.cth` file.  If the same standard cell is defined more than once,  then this is a fatal condition and will results in an error during processing.  However,  if --allow-duplicates is specified, multiple definitions are permitted, with the first .cth file taking precedence.  A duplicate summary report will be generated in either case.
  - Such a `.cth` line may carry an optional `REGEX=<regexp>` suffix on the **same line**, e.g. `76p5_g1i_opt8.cth  REGEX=tttt\S+850v\S+100c`. The pattern runs to end-of-line. Per die, all `REGEX=` patterns are collected as a **union** and used to build the optional `*.list.ctech.regex` outputs (see 3.0). Omit it when no filtering is needed.
  - All other non-empty content lines are **ctech structural release areas** (directory vanity paths), matched **exactly** as written.
- **Comment-only lines** beginning with `#` (pound sign, not a markdown heading) are permitted and ignored.
- Blank lines are ignored.

### 2.2 Path handling

- All paths are treated as **vanity paths** and are **NOT symlink-resolved** (e.g. `/p/hdk/cad/stdcells/`, `/p/hdk/cad/ctech/`).
- The directory paths under the dies are **ctech structural release areas** and must match `prep_tech.input.md` **exactly**.
- `.cth` files are located in the **Cheetah backend reference area** given in `prep_tech.input.md`.
- `.cth` parsing uses a **custom regex-based parser**.


### 2.3 DesignPackage resolution

The stdcell library root is **resolved from the `.cth`** `[DESIGNPACKAGE]` section, not from any `/p/hdk/cad/stdcells/...` entry in the die's ctech dirs.

The `lib_name` value contains one or more `designpackage(name=<pkg>,<field>)` tokens, for example:

```
i0m = designpackage(name=1278.6,path)/lib786_i0m_180h_50pp_pdk10_r8v2p0_fv
```

Resolution is **recursive token substitution** performed by a custom (self-written) parser:

- `designpackage(name=<pkg>,<field>)` resolves to the value of `<field>` in the same `[DESIGNPACKAGE]` section of the `.cth`.
- The substituted value may itself contain further `designpackage(...)` tokens; repeat substitution until none remain.

Worked example:

1. `lib_name`:
   ```
   designpackage(name=1278.6,path)/lib786_i0m_180h_50pp_pdk10_r8v2p0_fv
   ```
2. `designpackage(name=1278.6,path)` → the `path` field value, e.g.:
   ```
   /p/hdk/cad/dp_contour/78p6/designpackage(name=1278.6,version)
   ```
3. Nested `designpackage(name=1278.6,version)` → the `version` field value, e.g. `v1.0_2`.
4. Fully resolved stdcell library root:
   ```
   /p/hdk/cad/dp_contour/78p6/v1.0_2/lib786_i0m_180h_50pp_pdk10_r8v2p0_fv
   ```

The resolved path is treated as a **vanity path** (NOT symlink-resolved); the symlink at that location points to the actual release area. Bundle directories (e.g. `base_lvt`, `clk_svt`) and `*bmod.v` files are enumerated under this resolved root.

**Two `.cth` styles are supported:**

- **Explicit library field** (crt / i0m style): a field named exactly `<lib_name>` holds the library path (possibly via tokens), e.g. `i0m = designpackage(name=1278.6,path)/lib786_i0m_180h_50pp_pdk10_r8v2p0_fv`. The worked example above is this style.
- **Contour style (no explicit field):** `<lib_name>` has no matching field; only `path` and `version` are given. The library directory is then **discovered** under the resolved `path` by selecting the directory whose name (a) starts with `lib` and contains `_<lib_name>_`, (b) contains the **pitch** token from `lib_height_class` (e.g. `50pp`), and (c) ends in `_fv` (functional views). Lexically-first wins if several remain; error if none. Example: `/p/hdk/cad/dp_contour/76p5/v1.0_2/` + `lib_name=g1m` + `lib_height_class=g1m_8dg_50pp` → `lib765_g1m_240h_50pp_pdk10_r4v0p0_fv`.

---

## 2.4 Validation (pre-flight)

Confirm:
- All ctech directories exist and contain SystemVerilog files (`.sv`). ctech verilog files start with `ctech_lib`.
- All required `.cth` files exist in the Cheetah backend reference area.
- All `REGEX=` patterns compile as valid Python regular expressions.

Validation raises on the first missing path. Two non-writing modes are provided:
- `--check` — parse + validate only; print a one-line OK summary; write and plan nothing.
- `--dry-run` — parse, validate, and print the planned output paths **without writing** any files.
- `--allow-duplicates` — allow multiple `.cth` files to define the same standard cell. By default, this is disallowed and will raise an error if duplicates are found. 

## 3. Outputs (the generated tree)

If `$WORKAREA` is set, create a directory `prep_tech` under `$WORKAREA`; otherwise create it in the current working directory. Output filenames are **bare** (no `<tech>` prefix — a die may list multiple `.cth` files resolving to different libraries, so a single per-die tech prefix is ambiguous and was removed). The output tree is:

```
$WORKAREA/prep_tech/
├── <die>/
│   ├── static_stdcells.f            # stdcell *bmod.v files for ctech-referenced bundles only (see 3.1)
│   ├── stdcell.ldb.list.ctech       # ctech-referenced: selected ldb/db file per referenced bundle
│   ├── stdcell.lib.list.ctech       # ctech-referenced: selected lib file per referenced bundle
│   ├── stdcell.ldb.list.ctech.regex # optional (only if REGEX given): regex-filtered ldb/db, per referenced bundle
│   ├── stdcell.lib.list.ctech.regex # optional (only if REGEX given): regex-filtered lib, per referenced bundle
│   ├── stdcell.ldb.list             # full: all stdcell ldb/db collateral for used bundles.
│   ├── stdcell.lib.list             # full: all stdcell lib collateral for used bundles.
│   └── stdcell.ndm.list             # full: all ndm files for used bundles. Consumed by synthesis.
├── prep_tech.report                 # per-die summary statistics (see 3.3)
└── prep_tech.csv                    # detailed ctech→stdcell mapping (see 3.4)
```

Repeat the `<die>/` directory for each die. `<die>` is the die heading name lowercased (e.g. `CORIMH DIE` → `corimh`).

For `static_stdcells.f`, the first line is `+define+functional`, followed by the list of `*bmod.v` files.

### 3.0 List file terminology (ctech-referenced vs full)

Two families of list files are produced per die. (The earlier term "minimal" was a poor choice and is deprecated; use "ctech-referenced".)

- **ctech-referenced lists** (`*.list.ctech`): the selected collateral for **only the bundles that contain a stdcell actually referenced by ctech**. One selected file per referenced bundle. These are the files needed to elaborate the ctech verilog.
- **regex lists** (`*.list.ctech.regex`): optional. For each **ctech-referenced bundle**, keep that bundle's **nldm** `lib/` collateral whose **basename matches any** of the die's `REGEX=` patterns (union / logical OR, `re.search`), routed to `.lib` vs `.ldb/.db`. Emitted only when the die specifies at least one `REGEX`. Because this is an **independent PVT-corner selection** (not a filter of the already PVT-selected `*.list.ctech`), it may contain **more than one file per bundle** and be larger than `*.list.ctech` — which may signal the designer should tighten the REGEX.
- **full lists** (`*.list`, no `.ctech` suffix): **all** collateral for **all bundles used in ctech**. Given the current rules, "all used bundles" and "ctech-referenced bundles" are the same set; the difference is that the full lists carry the complete collateral for those bundles while the `.ctech` lists carry only the single selected file per bundle.

### 3.1 `static_stdcells.f`

- First line is `+define+functional`.
- Followed by the list of stdcell `*bmod.v` files. Include `*bmod.v` files for **only the bundles that contain a referenced cell**.

### 3.2 List file formatting

- **One path per line.**
- **Comment-only lines** using `#` are permitted.
- Output entries are **sorted lexically** for deterministic output.
- Referenced collateral paths are used **as-is** (compressed collateral is referenced as-is; no decompression/copy).

### 3.3 `prep_tech.report`

- **Plain text**, written to the output root.
- Add the script name and date executed in the report header.
- Add a summary line for each die at the top of the report.  The same summary printed to STDOUT when the automation is ran.
- For each die, list:
  - Number of ctech cells found.
  - Number of stdcells referenced by the ctechs, **deduplicated** (a stdcell referenced by multiple ctechs is counted once). Stdcell names are unique per bundle.
  - Number of duplicate stdcell cell definitions found for the provided `.cth` files
  - Number of **unresolved stdcell instantiations** — ctech instances whose name begins with a die stdcell-library prefix (e.g. `g1i`, `g1m`, `i0m`, taken from each `.cth` `lib_name`) but has **no matching `*bmod.v` definition** in any bundle. Each is listed on its own indented line as `<stdcell> <- <ctech_cell> (<path to ctech .sv>)`. Tokens that do **not** match a known library prefix are treated as non-stdcell (ctech submodules / SV constructs) and are not reported. This is **report-only** (it does not fail the run).
  - `ctech-referenced .lib files` / `.ldb/.db files` — line counts of `stdcell.lib.list.ctech` / `stdcell.ldb.list.ctech` (one selected file per referenced bundle).
  - `regex-filtered .lib files` / `.ldb/.db files` — line counts of `stdcell.lib.list.ctech.regex` / `stdcell.ldb.list.ctech.regex` (shown only when the die has a `REGEX`).
  - `full-list .lib files` / `.ldb/.db files` — line counts of `stdcell.lib.list` / `stdcell.ldb.list`.

### 3.4 `prep_tech.csv`

- Written to the output root.
- Columns:
  ```
  die,ctech_cell,stdcell name,.cth file,stdcell library,path to stdcell verilog,path to ctech verilog
  ```
- `stdcell library` is the **bundle directory name** (e.g. `base_lvt`).
- `.cth file` is the `.cth` file that contributed the stdcell library for this reference (e.g. `76p5_g1i_opt8.cth`)
- `stdcell name` is extracted by **parsing the ctech `.sv` verilog files** (the instantiated stdcell module names). The `*bmod.v` files in each bundle determine which standard cells exist in that library.
- `path to stdcell verilog` is the bundle `*bmod.v` that defines the stdcell; `path to ctech verilog` is the `ctech_lib_*.sv` file that instantiates it.
- **All rows** are emitted (one per stdcell reference per ctech; deduplicated per bundle within a die).
- Example:
  ```
  corimh,ctech_lib_triplesync_setb,g1iinv000ab1n24x5,76p5_g1i_opt8.cth,base_lvt,<path to bmod.v>,<path to ctech .sv>
  ```

### 3.5 `prep_tech.duplicates.csv`

- Written to the output root.  Always contains the header row; data rows only when duplicates are found.
- Purpose is to detect whether there is overlap in the stdcell definitions across different `.cth` files for the same die and stdcell library.  Can cause problems with EDA tools.
- Columns:
  ```
  die,stdcell library,stdcell name,.cth file list
  ```
- `stdcell library` is the **bundle directory name** (e.g. `base_lvt`).
- `stdcell name` is extracted by **parsing the ctech `.sv` verilog files** (the instantiated stdcell module names). The `*bmod.v` files in each bundle determine which standard cells exist in that library.
- `.cth file list` is a colon-separated list of `.cth` files that contain the duplicates (e.g. `76p5_g1i_opt8.cth:76p5_g1i_opt16.cth`).

---

## 4. Per-output derivation rules

Cheetah stdcell release area is built roughly as follows:

/p/hdk/cad/stdcells/<tech>_<library>_<height>_<pitch>/<version>  
/p/hdk/cad/stdcells/lib764_g1i_210h_50pp/pdk110_r6v2p1_fv

The concrete stdcell library root is obtained via **DesignPackage resolution** (see 2.3), not by reading a `/p/hdk/cad/stdcells/...` path directly from the die's ctech dirs.

The trailing library directory name splits at the **4th underscore group**:
- `<tech>_<lib>_<h>_<pp>` (e.g. `lib786_i0m_180h_50pp`) — the library-prefix form.
- `<version>` (e.g. `pdk10_r8v2p0_fv`) — the release version segment.

> **Note (tech prefix removed).** Output filenames no longer carry a `<tech>` prefix (a die may list several `.cth` files resolving to different libraries, making a single per-die prefix ambiguous). The library-prefix form is retained here only as a naming reference; it is not used to name output files.

Under this area are directories for each `<stdcell function>_<variant>` — a **bundle**.

So for example, for base functions using the lvt variant, `base_lvt/`.

Under here you will find directories:  
ndm/  
verilog/  
lib/

ldb or db will be under lib/

Collateral may be compressed.

The lib and ldb files will have versions for each PVT corner (process, voltage, temperature). You are going to select one for the output. Choose the one that is closest tttt/typical and 650mV and 100c. If there is still a tie, select the first one you find in lexical order.

Select nldm format only. This nldm filter applies to `.lib`, `.ldb`, and `.db` selection alike (`.db` files also carry the `_nldm_` token).

For example, you will select the second file here:

lib764_g1i_210h_50pp_base_lvt_tttt_0p650v_100c_tttt_cmax_ccslnt.lib.gz  
lib764_g1i_210h_50pp_base_lvt_tttt_0p650v_100c_tttt_cmax_nldm.lib.gz  

### 4.1 Library-prefix form

- The library-prefix uses forms like `lib764_g1i_210h_50pp`, `lib786_i0m_180h_50pp`, and equivalent.
- Derived by splitting the resolved library directory name at the **4th underscore group** (see section 4). Retained for reference only; not used in output filenames.

### 4.2 Bundle selection (ctech-referenced / used bundles)

- Select **one file per bundle** — no more.
- Only include bundles actually referenced by the ctech. If the ctech references only `svt` and `lvt` cells, do **not** include `hvt` bundles.
- It is possible (though unusual) for a ctech verilog in an `lvt` directory to reference an `lvt` cell.

### 4.3 lib / ldb / db routing

- `.lib*` → `.stdcell.lib.list`
- `.db*` or `.ldb*` → `.stdcell.ldb.list`
- If there are duplicates between `.db` and `.ldb`, choose **`.ldb`**.
- The nldm filter (see section 4) applies to `.lib`, `.ldb`, and `.db` selection.

---

## 5. Architecture & module responsibilities

Data flows as plain Python **dicts** between modules (no dataclass layer is required). Each module has a single responsibility:

```
prep-tech/
├── src/
│   └── prep_tech/
│       ├── __init__.py
│       ├── main.py       # CLI entrypoint (argparse; --check, --dry-run); orchestration
│       ├── config.py     # parse prep_tech.input.md -> dict (custom regex parser; no 3rd-party deps)
│       ├── discover.py   # .cth/.sv/bmod parsing, DesignPackage resolution, bundle enumeration, PVT+nldm selection
│       ├── validate.py   # pre-flight validation (raises on first missing path)
│       └── generate.py   # per-die plan build + output rendering/writing
├── tests/
│   ├── test_discover.py
│   ├── test_validate.py
│   └── test_generate.py
├── prep_tech.input.md
├── prep_tech.spec.md
├── pyproject.toml
└── README.md
```

Key data contracts:
- `config.parse_input(path) -> {"cheetah_backend": str, "dies": {<die>: {"cth_files": [...], "ctech_dirs": [...], "regexes": [...]}}}` (regexes = union of `REGEX=` patterns).
- `discover.resolve_lib_root(params)` — explicit-field style (`lib_name` -> field -> path via tokens) **or** contour style (discover under `path` by lib_name + pitch + `_fv`).
- `discover.enumerate_bundles(lib_root) -> {<bundle>: {root, bmod, cells, lib, ldb, ndm}}` (only dirs with a `verilog/*bmod.v`).
- `discover.compile_regexes(patterns)` / `discover.regex_filter(files, compiled)` — union `re.search` on basenames.
- `generate.build_die_plan(...) -> {bundles, referenced_keys, refs, ctech_cells, unresolved, regexes}`; `generate.generate_all(...)` writes the tree.

Output root resolution: `$WORKAREA/prep_tech/` if `WORKAREA` is set, else `./prep_tech/`.

## 6. CLI / usage

Run from the project root. If the package is not installed, put `src` on the path:

```bash
# Validate inputs only (no plan, no write)
PYTHONPATH=src python3 -m prep_tech.main prep_tech.input.md --check

# Plan + print planned outputs, write nothing
PYTHONPATH=src python3 -m prep_tech.main prep_tech.input.md --dry-run

# Full generation (writes $WORKAREA/prep_tech or ./prep_tech)
PYTHONPATH=src python3 -m prep_tech.main prep_tech.input.md
```

## 7. Testing

Tests are **hermetic** (pytest `tmp_path` fixtures build a fake backend + lib tree + ctech dir); they do not depend on real `/p/hdk` release areas.

```bash
PYTHONPATH=src python3 -m pytest -q
```

Coverage: `.cth`/DesignPackage resolution (incl. key-deref and mixed-case fields), ctech `.sv` instance parsing, bundle enumeration, PVT/nldm selection, input parsing, pre-flight validation, and end-to-end `generate_all` (tree + report + CSV).

---

## 8. Resolved decisions (formerly open questions)

**Verified on disk (2026-07):** 76p4 (crt) `.cth` carries an explicit `<lib_name>` field; 78p6 i0m carries `i0m = .../lib786_i0m_180h_50pp_..._fv`; 76p5 (contour) g1i/g1m `.cth` have **no** `<lib_name>` field — the library is discovered under `path`. Bundle dirs contain `verilog/*bmod.v`, `lib/` (`*.lib.gz`, `*.ldb`), and `ndm/`. PVT tokens look like `tttt_0p650v_100c`; `nldm` vs `ccslnt` distinguishes format.

**Q1.** ctech-referenced lists (`stdcell.lib.list.ctech`, `stdcell.ldb.list.ctech`): each entry is the selected `.lib`/`.ldb` file for **only the bundles that contain a stdcell actually referenced by ctech**.  
> **Resolved:** Correct.

**Q2.** `.db` nldm token.  
> **Resolved:** `.db` files carry the `_nldm_` token; the nldm filter applies to `.db` selection.

**Q3.** Full vs ctech-referenced semantics.  
> **Resolved:** Correct. "Minimal" wording deprecated in favor of "ctech-referenced" (see 3.0).

**Q4.** `static_stdcells.f` scope.  
> **Resolved:** Only bundles that contain referenced cells.

**Q5.** ctech `.sv` file location.  
> **Resolved:** Always directly within the listed ctech structural release area directories.

**Q6.** Stdcell library root source.  
> **Resolved:** Resolved from the `.cth` `lib_name`/`path`/`version` fields via DesignPackage resolution (see 2.3).

**Q7.** Output filename `<tech>` prefix.  
> **Resolved:** Removed. A die may list multiple `.cth` files resolving to different libraries, making a single per-die prefix ambiguous. Filenames are bare.

**Q8.** Unresolved stdcell instantiations (ctech instance with no `*bmod.v` definition).  
> **Resolved:** Detected and **reported** (not fatal). A token is flagged only when it begins with a die stdcell-library prefix (from `.cth` `lib_name`) yet has no matching definition, keeping false positives (ctech submodules / SV constructs) out. Listed per die in `prep_tech.report` (see 3.3).

**Q9.** Library-root resolution when the `.cth` has no explicit `<lib_name>` field (contour style).  
> **Resolved:** Discover under the resolved `path` the directory matching `lib*_<lib_name>_*`, filtered by the **pitch** token from `lib_height_class` (e.g. `50pp`) and preferring **`_fv`** (functional views); lexically-first on ties, error if none (see 2.3).

**Q10.** REGEX filtering semantics (`*.list.ctech.regex`).  
> **Resolved:** For each ctech-referenced bundle, keep the bundle's **nldm** `lib/` collateral whose basename matches **any** die `REGEX` (union, `re.search`), routed to lib vs ldb/db. Independent PVT selection (not a filter of `*.list.ctech`); may exceed one file per bundle. Emitted only when a `REGEX` is present. Invalid patterns fail validation early (see 2.1 / 2.4).

**Q11.** Re-run hygiene / stale outputs.  
> **Resolved:** Generation writes in place (`os.makedirs(exist_ok=True)`; no `rmtree`, so it is NFS-safe). It does **not** prune stale files when an input contracts (e.g. a die drops a bundle, or a `REGEX` is removed so `*.list.ctech.regex` should no longer exist). Remove the die/output directory manually if the input set shrinks.

---

## 9. Reusable automation template

Use this section as the skeleton for a new generative/idempotent automation. Keep each section's **contract**; replace the domain content.

1. **Purpose** — one paragraph: what it generates, that it is idempotent, and what it must *not* do (e.g. not run downstream flows, not modify sources).
2. **Inputs (sources of truth)** — table of inputs; define a **machine-readable** input format (headings, required vs optional lines, comment/blank handling). Allow optional per-line modifiers (here: `REGEX=` on a `.cth` line) and state how repeats combine (union). State **precedence** when the same logical item is defined by multiple sources (here: the first-listed `.cth` wins).
3. **Path & resolution handling** — state vanity-path vs symlink-resolution policy; describe any **indirection/token resolution** (here: DesignPackage key-deref + recursive `designpackage(...)` substitution) with a worked example, and cover **multiple input styles / fallbacks** for the same logical value (here: explicit library field vs contour discovery under `path`).
4. **Validation & non-writing modes** — enumerate pre-flight checks; provide `--check` (validate only) and `--dry-run` (plan only, no writes).
5. **Outputs (generated tree + file formats)** — show the exact tree; specify each file's content, ordering (sorted/deterministic), and comment conventions. Mark **optional** outputs and their trigger conditions (here: `*.list.ctech.regex` only when a `REGEX` is given). Give the human report a **header** (tool name + run timestamp) and a **top summary** printed identically to STDOUT; surface anomalies as **report-only** entries (don't fail the run).
6. **Derivation / selection rules** — how concrete artifacts are chosen (here: bundle enumeration, PVT-closest + format filter, one-per-group selection, routing by extension).
7. **Architecture & module responsibilities** — one module per concern (`config` parse, `discover` resolve/enumerate/select, `validate`, `generate` plan+render+write); pass plain dicts; define the key data contracts.
8. **CLI / usage** — exact commands, including how to run without installation.
9. **Testing** — hermetic fixtures; list what each area covers.
10. **Resolved decisions** — capture Q/A so future readers see the rationale behind non-obvious choices.