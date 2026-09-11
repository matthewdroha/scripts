# cthrepo-to-zenws

Plan the graft of changes made between two Cheetah repo tags into an already
migrated zen workspace, and emit a replay script, a summary and a timestamped
CSV plan.

## Status

Working. 79 tests pass.

## How it works

1. `git diff <base> <head> --name-status` on the Cheetah repo defines the scope of
   work — 542 entries for the reference range (353 A, 113 M, 7 D, 69 R). Git's default
   rename detection is left on, so a rename arrives as one `R<similarity>` row carrying
   both endpoints, which is what lets a rename be replayed as a move rather than as an
   unrelated add and delete.
2. The workspace `migration_report.txt` supplies 3883 explicit source →
   destination pairs plus the category mapping rules used during migration.
3. Each changed file is resolved to a zen destination, its content change is
   classified, and it lands in an action bucket.

### Destination resolution

Candidates are generated in trust order, but **a candidate that names a file
which actually exists always wins** — a speculative category rule must not beat a
lower-ranked candidate pointing at the real file.

| Source | Meaning |
| --- | --- |
| `migration-report` | Explicit `SRC:`/`DST:` pair in the report |
| `identity-path` | Same relative path already exists in the workspace |
| `sibling-directory` | Every other file in this source directory maps to one destination directory |
| `category-rule` | Matches a `--- RTL CATEGORY MAPPING ---` / `--- VAL PASS-THROUGH MAPPING ---` rule |
| `identity-directory` | The source directory exists verbatim in the workspace |
| `unique-basename` | Exactly one file of that name exists anywhere in the workspace |
| `unresolved` | Nothing matched; needs a human |

### Action buckets

| Bucket | Meaning |
| --- | --- |
| `auto-add` | New file with a trusted destination that does not yet exist |
| `auto-update` | Workspace copy still byte-identical to the base tag |
| `auto-delete` | Workspace copy still byte-identical to the base tag |
| `auto-rename` | Both endpoints resolve, old copy untouched, new slot free |
| `review-add-inferred-path` | New file, destination was guessed |
| `review-comment-only` | Only comments changed upstream |
| `review-whitespace-only` | Only whitespace changed upstream |
| `review-delete` | Deleted upstream but locally modified |
| `manual-merge` | Workspace copy diverged from the base tag |
| `manual-rename` | Rename whose old copy diverged, or whose new path will not resolve |
| `manual-locate-destination` | No usable destination |
| `skip-up-to-date` | Workspace copy already matches head |
| `skip-ignored` | Matched an `--ignore` pattern |
| `skip-not-migrated` | Deleted upstream, never migrated in |

Only `auto-*` lines are live in the replay script. Everything else is emitted
commented out behind a `# TODO(<bucket>)` marker.

## Run

```bash
uv run cthrepo-to-zenws \
  --cheetah-repo   /path/to/rtls.ichassis.components-mainline \
  --zenws-repo     /path/to/1-components-main \
  --cheetah-tag-used-for-existing-zenws aisoc_migration \
  --cheetah-tag-to-graft-to-zenws       aisoc_migration_3 \
  --verbose --debug 3
```

Add `--dry-run` to plan without writing, `--force` to overwrite existing
outputs, `--ignore FILE` to skip fnmatch patterns, `--outdir DIR` to redirect
the artifacts. Exit code is 0 on success and 2 on a preflight failure.

## Outputs

Written to the workspace root (or `--outdir`):

| File | Contents |
| --- | --- |
| `cthrepo-to-zenws.replay` | Executable bash; runs the automatic actions, TODOs the rest |
| `cthrepo-to-zenws.replay.review` | Same buckets and order, as cut-and-paste `meld <src> <dest>` lines |
| `cthrepo-to-zenws.review-src/` | Cheetah sources at the head tag, staged so `meld` has real files |
| `cthrepo-to-zenws.summary` | Command line, start/end time (human and epoch), counts, every file by bucket |
| `cthrepo-to-zenws.csv.<timestamp>` | One row per changed file, never overwritten |
| `cthrepo-to-zenws.log` | Per-file decisions, only with `--debug` |

In `.replay.review` a line is live when both sides exist and is commented out when
there is nothing to diff — a new file whose destination is not there yet, a delete with
no upstream source, or an unresolved destination. The reason follows the command on the
same line. Renames are diffed against the *old* zen copy, since that is the file that
exists today.

## Test

```bash
uv run pytest
```
