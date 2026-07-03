---
description: "Generate or update a README.md with a table of contents, repo clone instructions, and either per-script or per-directory summaries depending on repo size"
agent: "agent"
argument-hint: "Optional: path to README.md (defaults to ./README.md)"
tools: ["search", "runCommands", "edit"]
---
Generate (or update) the README.md for this repository following the structure and conventions below. If a README.md already exists, preserve any existing prose in the `Overview` section but rebuild the `Table of Contents` and `Scripts` sections from scratch so they stay in sync with the repo contents.

## 1. Determine the clone URL

Run `git remote -v` in the repository root to find the origin URL. Derive the `org/repo` slug from it (works for both `https://github.com/org/repo.git` and `git@github.com:org/repo.git` forms). If there is no git remote, ask the user for the GitHub `org/repo` slug before proceeding.

## 2. Survey the repository and choose a Scripts granularity

Before writing anything, get a factual picture of the repo so you can pick the right level of detail. Do NOT descend into `.git`, `.github`, `node_modules`, `venv`, or other dependency/build directories.

1. List the directory tree and count script/executable files (e.g. `.sh`, `.csh`, `.pl`, `.py`, `.rb`, `.ps1`, `.tcl`, and other files with a shebang or execute bit):

    ```bash
    find . -type d \( -name .git -o -name .github -o -name node_modules -o -name venv \) -prune \
      -o -type f \( -name '*.sh' -o -name '*.csh' -o -name '*.pl' -o -name '*.py' \
                    -o -name '*.rb' -o -name '*.ps1' -o -name '*.tcl' \) -print | sort
    ```

2. Based on the count and structure, choose ONE granularity:
   - **Per-script** (default for small/flat repos): roughly **≤ 40 scripts**, or a simple top-level / `bin/`-style layout. Document every script individually (see §5a).
   - **Per-directory overview** (for large or deeply-nested repos): **> 40 scripts** or many nested category directories. Summarize each top-level category directory and its subdirectories instead of every file (see §5b).

   If the choice is borderline or the user gave explicit scope, honor the user's intent. When you auto-select per-directory overview for a large repo, state that choice in one sentence before writing.

3. Ground your descriptions in evidence, not guesses. Sample representative files to learn the domain: read shebangs, header comments, POD/`__END__` docs, argument parsing, and `Functional Description:`/`Project:` header lines. For per-directory mode, read at least one representative script per top-level category, and note recurring subdirectory naming conventions (e.g. `sch/`, `std/`, `utils/`, `pdv/`, `mig/`, `status/`, `cron/`).

## 3. Table of Contents

Add a `## Table of Contents` section directly under the title, before `## Overview`. It must contain a nested list whose links resolve to real heading anchors:

- `Overview`
- `Usage`
  - `Cloning the Repository`
- `Scripts`
  - one entry per item documented in the Scripts section:
    - **Per-script mode**: one entry per script, linking to that script's subheading (e.g. `[foo.sh](#foosh)`). Add nesting levels to mirror the script's location in the directory structure.
    - **Per-directory mode**: one entry per top-level category directory, linking to that directory's subheading (e.g. `[ivb](#ivb)`).
- any additional top-level sections you keep (e.g. `Requirements`, `Contributing`, `License`) so the TOC stays complete.

## 4. Usage / Cloning the Repository

Under `## Usage`, add a `### Cloning the Repository` subsection listing all 3 supported clone methods as an ordered list, substituting the actual `org/repo` slug discovered in step 1. Do not use bold text as a pseudo-heading (avoid MD036 lint violations) — an ordered list item is sufficient. Put each command in its own fenced code block, indented to align with the list item's content (4 spaces) so the code fence doesn't break the surrounding Markdown list:

```markdown
1. HTTPS

    ```bash
    git clone https://github.com/<org>/<repo>.git
    ```

1. SSH

    ```bash
    git clone git@github.com:<org>/<repo>.git
    ```

1. GitHub CLI

    ```bash
    gh repo clone <org>/<repo>
    ```
```

## 5. Scripts section

Write a `## Scripts` section using the granularity chosen in §2.

### 5a. Per-script mode (small/flat repos)

Scan the repository (top-level, and any obvious `bin/`-style script directories) for scripts and executables. For each script:

- Read enough of the file (shebang, argument parsing, `__END__`/POD docs, header comments, main logic) to understand its purpose.
- Add a `### <script-name>` subheading under `## Scripts` with a concise 1-3 sentence summary of what it does: its purpose, key inputs/arguments, and any important side effects (e.g. files it reads/writes, hosts it connects to, other scripts it depends on).
- Also include any plain data files that other scripts clearly depend on (e.g. CSV config, include lists) with a short description of their role.
- Skip generated/log output files (e.g. `*.log`) and non-script assets.
- Keep each summary short and factual — do not speculate beyond what the code shows. Order scripts alphabetically to match their order in the Table of Contents.

### 5b. Per-directory overview mode (large/nested repos)

- Open with one sentence stating the repo's approximate scale (e.g. "~200 scripts across ~80 nested directories") and that the section summarizes directories rather than individual files.
- If the same functional subdirectory names recur across top-level directories, add a small table in `## Overview` mapping each common subdir name to its role (e.g. `sch/` → schematic tools, `std/` → shared library modules).
- Add one `### <top-level-dir>` subheading per top-level category directory, in the same order as the Table of Contents (alphabetical unless a more meaningful order exists).
- Under each `###` heading, give a one-line description of the directory's purpose, then a Markdown table with two columns — the subdirectory path and a short factual summary of its contents (naming a few representative scripts and any key data/config files). Keep summaries factual; do not speculate beyond what the sampled files show.
- Mention shared library/module directories and important data files (CSV, `.list`, config) where scripts clearly depend on them.

## 6. Validate

After writing the file:

- Confirm every Table of Contents link has a matching heading anchor (GitHub-style: lowercase, spaces to `-`, punctuation other than `-`/`_` stripped). A quick check:

    ```bash
    grep -oE '\(#[a-z0-9_-]+\)' README.md | tr -d '(#)' | sort -u > /tmp/toc
    grep -E '^#{2,3} ' README.md | sed -E 's/^#+ //; s/[A-Z]/\L&/g; s/ /-/g; s/[^a-z0-9_-]//g' | sort -u > /tmp/heads
    comm -23 /tmp/toc /tmp/heads   # any output = broken TOC links
    ```

- In per-script mode, confirm no scripts were missed. In per-directory mode, confirm every top-level category directory has a heading and TOC entry.
