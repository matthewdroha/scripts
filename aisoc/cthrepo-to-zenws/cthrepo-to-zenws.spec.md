# Spec: `cthrepo-to-zenws` — Automation to carefully graft changes from a Cheetah repo into a zen workspace

Status: **Phase 3 implemented** (2026-08-29) — replay/summary/csv/log all generated; see §8.
Owner: mroha
Language: **Python 3.13**, packaged as a `uv` project with a `src/` layout and a `pytest`
suite, per `scripts/.github/instructions/python-uv-tool.instructions.md`.
Scope: Build a replay file that can transpose a Cheetah repo into a zen workspace,  with careful handling of the files that are added, modified, or deleted in the Cheetah repo.  The files identified are determined from a git diff call,  where one tag is what the zen repo was originally build from, and the second tag is an update to the Cheetah repo that we want to graft into the zen workspace.

---

## 1. Purpose

`cthrepo-to-zenws` Accepts two repos as input, the original zen workspace repo and the updated Cheetah repo.  The targeted differences are strictly limited to what files changed between two provided tags in the Cheetah repo.  The workflow will generate a replay file that can be used to update the zen workspace repo with the changes from the Cheetah repo.  The replay file will contain a list of files that were added, modified, or deleted in the Cheetah repo, and will provide instructions for how to apply those changes to the zen workspace repo. 

The workflow is **generative and idempotent**: re-running it reproduces the same output
tree from the same inputs.

---

## 2. Inputs (sources of truth)

Lines beginning with `#` are comments and ignored.  Blank lines are ignored.  The following table summarizes the inputs to the workflow.

| # | Source | Provides | Notes |
|---|--------|----------|-------|
| S1 | **Cheetah repo** — e.g. /nfs/site/disks/ich/frontend.01/mroha/rtls.ichassis.components-mainline | Changes that will be projected onto Zen workspace | Single git repo |
| S2 | **Zen workspace** — e.g. /nfs/site/disks/ich/frontend.01/mroha/1-components-main | The workspace that will be updated with changes from the Cheetah repo | A *workspace*, not a repo: it contains several independent git sub-repos (`components`, `project-config`, `lib.idl-design-lib`, `lib.aitools`) plus a `.zen/` metadata directory |
| S3 | **Original Cheetah tag** - e.g. aisoc_migration | The tag in the Cheetah repo that was used to build the current Zen workspace | |
| S4 | **Cheetah tag to graft** - e.g. aisoc_migration_03 | The tag in the Cheetah repo that contains the changes to be grafted into the Zen workspace | |
| S5 | **Migration report** — `<zenws>/*/migration_report.txt` | Authoritative Cheetah-path → Zen-path mapping produced when the workspace was created | Auto-discovered; overridable with `--migration-report`. The sub-repo that owns the report is the default destination root. |
| S6 | **Ignore file** (optional, `--ignore`) | Regexes for Cheetah paths that are deliberately out of scope | One pattern per line, optionally double-quoted |

### 2.1 The migration report

The report is emitted by the RTL migration tool. Two parts of it are consumed:

- **`SRC:` / `DST:` pairs** (3883 in the reference workspace). Both sides are absolute
  paths under the single `Repo root:` declared in the header; both are made relative to
  that root, producing an exact per-file mapping. Pairs whose `SRC:` lies outside the
  repo root are dropped.
- **`--- RTL CATEGORY MAPPING ---` and `--- VAL PASS-THROUGH MAPPING ---` sections**,
  which declare directory-level rules such as
  `src/rtl/fabric/<block>/ -> BLOCKS/fabric/<block>/design/rtl/` and
  `src/rtl/pkg/ -> COMMON/pkg/design/rtl/<subpath>`. `<name>` placeholders bind one path
  segment; `<subpath>` binds the remainder. A source appearing twice with different
  destinations, or a destination containing an alternation (`pkg|env`), is ambiguous and
  discarded. Remaining rules are tried most-specific-first (most literal segments wins).

### 2.2 Validation (pre-flight)

An error is raised and the run aborts (exit 2) if any of the following fail:

- `--cheetah-repo` exists, is a directory, and is a git repository.
- Both tags resolve to commits in the Cheetah repo.
- `--zenws-repo` exists and contains at least one git sub-repository.
- The migration report, if given or discovered, is a readable file.
- The `--ignore` file, if given, is a readable file.

---

## 2.3 Determining scope of changes to graft into the zen workspace

Scope is exactly:

```
git diff <base-tag> <head-tag> --name-status
```

Git's default rename detection is left on, so a rename arrives as a single
`R<similarity>` row carrying both endpoints. That is deliberate: the old and new paths
are needed together to replay the change as a move (§4.3). A type change (`T`) is treated
as a modify. Nothing outside this diff is ever considered.

For `aisoc_migration..aisoc_migration_3` this is **542 entries: 353 A, 113 M, 7 D, 69 R**.

Two variants were measured and rejected:

| Command | Entries | Why not |
|---|---|---|
| `--diff-filter=ADM` | 473 | The filter discards the 69 `R` rows outright — those files vanish |
| `--no-renames` | 611 | Nothing is lost, but each rename becomes an unrelated add plus delete, so the move cannot be replayed as a move |

The zen `components` sub-repo at `aisoc_migration` is roughly content-equivalent to the
Cheetah repo at that tag; this is what makes the base-tag byte comparison in §4.3 a
reliable divergence test.

---

## 3. Outputs (the generated tree)

Generated in the zen workspace root (or `--outdir`):

```
<zenws>
├── cthrepo-to-zenws.replay                     # executable bash replay script
├── cthrepo-to-zenws.replay.review               # meld commands for visual review
├── cthrepo-to-zenws.review-src/                 # head-tag sources staged for meld
├── cthrepo-to-zenws.summary                    # human-readable plan + counts
├── cthrepo-to-zenws.csv.<YYYY-MM-DD_HH-MM-SS>  # one row per changed file
└── cthrepo-to-zenws.log                        # run metadata / debug detail
```

The csv is timestamped so successive plans can be diffed as the workspace converges.
The replay and summary are overwritten each run (idempotent for fixed inputs).

## 3.1 .csv file format

Header row, then one row per file in the diff:

```
filename, cheetah_source_path, change, resolution_rule, action_bucket, zen_destination_path, zen_previous_path, notes
```

`change` is `add` / `modify` / `delete` / `rename`. `resolution_rule` is the rule that
actually produced the destination (§4.1) — one of `migration-report`, `identity-path`,
`sibling-directory`, `category-rule`, `identity-directory`, `unique-basename`, or
`unresolved` — so a reviewer can judge how much to trust the row before opening it.
`zen_previous_path` is populated only
for renames, and carries the destination the old Cheetah path resolves to. If the bucket
is a no-action bucket
(`skip-up-to-date`, `skip-ignored`, `skip-not-migrated`), `zen_destination_path` is blank
and `notes` carries the reason for skipping.

---

## 4. Per-output derivation rules

### 4.1 Destination resolution

Every changed path is resolved to a workspace-relative destination by collecting
candidates in trust order and then preferring the first candidate that points at a file
that **actually exists**; if none exists (the normal case for new files) the most trusted
candidate is used. This ordering matters: a speculative rule must never outrank the
observable location of a real file.

| Method | Basis |
|--------|-------|
| `migration-report` | Explicit `SRC:`/`DST:` pair |
| `identity-path` | Same relative path already present in a sub-repo |
| `sibling-directory` | The Cheetah directory maps to exactly one zen directory across all report entries |
| `category-rule` | Directory rule parsed from the report's mapping sections (§2.1) |
| `identity-directory` | The Cheetah directory exists verbatim in a sub-repo |
| `unique-basename` | Exactly one file with that basename anywhere in the workspace |
| `unresolved` | No candidate — the file has no home in the workspace |

### 4.2 Content-shape classification

For a modified file the base blob, head blob, and current zen file are compared byte for
byte. When the zen copy has diverged from the base tag, the *upstream* change is further
classified so low-risk changes can be separated from real merges:

- `identical` — bytes equal.
- `whitespace` — equal after collapsing runs of whitespace and dropping blank lines.
- `comment` — equal after stripping comments. `//` and `/* */` for
  `.c/.cc/.cpp/.h/.hpp/.sv/.svh/.v/.vh`; `#` for
  `.f/.list/.cfg/.cth/.mk/.pl/.pm/.py/.sh/.tcl/.yaml/.yml` and `Makefile*`. Files with no
  known comment syntax are never classified as comment-only.
- `binary` — either side is not valid UTF-8.
- `code` — everything else.

### 4.3 Action buckets

| Bucket | Condition |
|--------|-----------|
| `auto-add` | Add; destination from the migration report; nothing there yet |
| `auto-update` | Modify; zen copy still byte-identical to the base tag |
| `auto-delete` | Delete; zen copy still byte-identical to the base tag |
| `auto-rename` | Rename; both endpoints resolve, the old zen copy still matches the base tag, and the new destination is free |
| `review-add-inferred-path` | Add; destination came from a heuristic, not the report |
| `review-comment-only` | Modify; zen diverged, upstream change is comment-level |
| `review-whitespace-only` | Modify; zen diverged, upstream change is whitespace-level |
| `review-delete` | Delete; zen copy has local edits |
| `manual-merge` | Modify with a code-level upstream change against a diverged zen copy, or an add or rename whose destination already exists |
| `manual-rename` | Rename whose old zen copy diverged from the base tag, or whose new path has no destination |
| `manual-locate-destination` | No destination derivable, or the resolved file is absent |
| `skip-up-to-date` | Zen copy already matches the head tag |
| `skip-ignored` | Matched an `--ignore` pattern (evaluated before any content read) |
| `skip-not-migrated` | Deleted upstream; no counterpart exists in the workspace |

### 4.4 .replay

A `set -euo pipefail` bash script with two helpers:

- `graft <cheetah-path> <zen-relative-path>` — `mkdir -p` the destination directory, then
  `git -C $CTH_REPO show $HEAD_TAG:<path>` into it. Content comes from git, never from the
  Cheetah working tree, so the replay is reproducible from the tag alone.
- `drop <zen-relative-path>` — `rm -f`.

Entries are grouped by bucket in the order of §4.3. `auto-*` buckets emit live commands.
A rename emits `graft` for the new destination followed by `drop` of the old one, and the
`drop` is omitted when both Cheetah paths resolve to the same zen file. Every other bucket
emits a `# TODO(<bucket>): <path> — <reason>` line followed by commented-out commands, so
a reviewer can uncomment them after making a decision. The script is written with mode
0755.

### 4.4.1 .replay.review

The same buckets in the same order as §4.4, but rendered as `meld <src> <dest>` lines
with both sides fully resolved to absolute paths, so a reviewer can paste any single line
into a shell.

Because the Cheetah side of a comparison is a git blob rather than a file on disk, the
head-tag sources are extracted once per run into `cthrepo-to-zenws.review-src/` with a
single `git archive`. The review file is therefore correct regardless of what the Cheetah
working tree happens to be checked out at. The staging directory is rebuilt on every run.

A line is live when the destination file exists, and commented out with the reason
appended when it does not:

| Case | Line |
| --- | --- |
| destination exists | `meld <staged-src> <zen-dest>` |
| destination not created yet | `# meld <staged-src> <zen-dest> # destination does not exist yet` |
| delete | `# meld <zen-dest> # deleted upstream, no source to compare` |
| no destination resolved | `# meld <staged-src> ? # no destination resolved` |
| no-action bucket | `# <cheetah-path>: <reason>` |

A rename is diffed against the **old** zen path, because that is the file that exists in
the workspace today; the new path usually does not exist until the replay runs.

### 4.5 .summary

Per repository preference, the summary opens with the exact command line, the start and
end time in both human-readable and epoch form, and the elapsed seconds. Then the inputs
(repos, tags, the literal diff command, migration report, map size, rule count), a count
summary (changed / automatable / needs-review / no-action), counts by bucket, a legend
giving the meaning of each bucket that the run actually produced, then every file listed
under its bucket with its destination, resolution rule and note. The legend covers only
the buckets present in the counts, so it never describes work that is not there.

### 4.6 .log

Written only when `--debug` is non-zero. Always carries the command line, start and end
times (human and epoch) and the diff command. `--debug 1` adds per-bucket counts,
`--debug 3` adds every plan row, `--debug 5` adds every note.

---

## 5. CLI

```
cthrepo-to-zenws \
  --cheetah-repo <path>     # No default, required.
  --zenws-repo <path>       # No default, required.
  --cheetah-tag-used-for-existing-zenws <tag>  # No default, required.
  --cheetah-tag-to-graft-to-zenws <tag>  # No default, required.
  [--migration-report <path>]  # Default: <zenws>/*/migration_report.txt
  [--ignore <path>]            # fnmatch exclusion list
  [--outdir <path>]            # Default: the zen workspace root
  [--dry-run] [--force] [--verbose] [--help] [--debug <0-5>]
```

Behavior:
- `--dry-run` prints the planned counts without writing.
- `--force` overwrites existing output files; without it an existing output is an error.
- `--verbose` streams progress to stderr through an injectable `log` callable.
- `--debug <level>` writes the log file at the specified detail level (1-5).

Exit codes: `0` success, `2` pre-flight validation failure or a refused overwrite.

---

## 6. Resolved questions & remaining notes

- **The zen "repo" is a workspace of repos.** Destinations are therefore
  workspace-relative (`components/BLOCKS/...`), and the sub-repo that owns the migration
  report is the default destination root.
- **The migration report is the primary source of truth**, not a path-rewriting heuristic
  invented here. Heuristics only fill gaps the report does not cover.
- **Existence beats trust rank.** Resolution prefers a candidate that names a real file;
  without this, category rules mis-routed files that had actually been placed elsewhere
  (measured: 6 auto-deletes and 22 manual-merges were being lost).
- **Renames are kept whole and mostly automated.** Plain `--name-status` keeps rename
  detection on so both endpoints arrive together and the change can be replayed as a
  move. A rename is automated only when the old zen copy still matches the base tag and
  the new destination is free; 64 of 69 qualify in the reference range. Filtering with
  `--diff-filter=ADM` would have discarded all 69 rows, and `--no-renames` would have
  split them into unrelated adds and deletes.
- **The remaining unresolved files are real, not a tool gap.** For the reference range
  they are `verif/sim`, `syn/fc`, `syn/rtlaqor`, `filelists/`, and a few top-level
  infrastructure files — areas the migration never brought into the workspace.

---

## 7. Test plan

`tests/` (79 tests, `uv run pytest`), one module per source module:

- `test_gitdiff.py` — the diff command shape, `--name-status` parsing including
  `R<similarity>` with both endpoints, type change and malformed lines, `blob_at`, repo
  and rev probes, and a real diff against the fixture repo.
- `test_migration.py` — SRC/DST relativization, out-of-root rejection, unpaired SRC,
  directory-map ambiguity, category rule placeholder binding, `<subpath>` handling,
  ambiguity and alternation rejection, specificity ordering.
- `test_content.py` — comment style by suffix, identical, whitespace-only, line- and
  block-comment-only, code, unknown-suffix, binary.
- `test_workspace.py` — sub-repo and report discovery, destination root, basename index
  skipping `.git`, each resolution method, and the existence-beats-trust-rank rule.
- `test_plan.py` — every bucket transition on an on-disk fixture: a temporary git repo
  with `base_tag`/`head_tag` and a matching zen workspace, plus bucket ordering and
  ignore-pattern parsing.
- `test_outputs.py` — csv header and row count, the generated replay is executed with
  `bash` and asserted to apply the auto actions while leaving reviewed files untouched,
  every non-auto row is behind a `# TODO`, summary carries the command line and both time
  formats, `--force` clobber protection, log written only with `--debug`.
- `test_cli.py` — required flags present, dry-run writes nothing, a real run writes the
  artifacts, `--outdir`, second run needs `--force`, verbose goes to stderr, and each
  pre-flight failure exits 2.

---

## 8. Implementation plan (phased)

- For every phase of implementation,
  - Write unit tests for the new functionality.
  - Implement the new functionality.
  - Run unit tests to verify the new functionality works as expected.
  - Update the implementation plan with any changes or new phases.
  - Update `README.md` with the new functionality and how to use it.
  - Always update the spec (this document) in a way which makes it useful as a template for future development.

**Phase 1 — done.** First pass study of the Cheetah and Zen repos. Findings: the zen
"repo" is a multi-repo workspace; the migration report carries 3883 explicit SRC/DST pairs
plus directory-level category rules.

**Phase 2 — done.** Deeper study on content differences. Adds and deletes were indeed the
easier cases once a destination could be derived; the hard part was destination derivation
for new files, solved by the candidate ladder in §4.1. Modified files are split by content
shape (§4.2) so comment- and whitespace-only upstream changes are separated from real
merges. Every file lands in exactly one bucket — there is no unhandled residue.

**Phase 3 — done.** Automation generates `.replay`, `.summary`, `.csv.<datetime>`, and
`.log`. The timestamped csv is the tracking artifact for how the plan changes over time.

**Phase 4 — done.** Repackaged as a `uv` project (`src/` layout, console script, pytest).
Diff scope settled on plain `--name-status`, and renames are now planned as moves with an
`auto-rename` bucket.

Reference-range measurement for `aisoc_migration..aisoc_migration_3` (542 files):

| Bucket | Count |
|---|---|
| `auto-add` | 18 |
| `auto-update` | 106 |
| `auto-delete` | 6 |
| `auto-rename` | 64 |
| `review-add-inferred-path` | 235 |
| `manual-merge` | 31 |
| `manual-rename` | 1 |
| `manual-locate-destination` | 80 |
| `skip-not-migrated` | 1 |

Totals: 194 automatable, 347 needing review or merge, 1 no-action.

**Phase 5 — next.** Iterate as outliers are discovered. Known follow-ups:
- 235 of the review rows are `review-add-inferred-path`, so tightening add-destination
  confidence is the highest-leverage next step.
- 53 of the 64 `auto-rename` rows resolve both Cheetah paths to the *same* zen file: the
  migration had already flattened the move, so the action is really an update, not a
  rename. Reclassifying those would make the bucket counts honest.
- Consider auto-applying `review-whitespace-only` behind an opt-in flag.

---

## 9. Non-goals (for now)

- Committing, branching, or pushing in the zen workspace. The replay only touches the
  working tree; git operations stay with the user.
- Three-way textual merging. Files that need a merge are reported, not merged.
- Grafting anything outside the two-tag diff.
- Rewriting filelists/`.f` contents to match relocated paths.
