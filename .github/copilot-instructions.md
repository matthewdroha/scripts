# GitHub Copilot – scripts Repository Instructions

All instructions for this repository live in [AGENTS.md](../AGENTS.md) at the repository
root, so Copilot, Claude Code and other agents read the same file.

Keeping the same rules in two always-on files is an anti-pattern — they drift. Edit
`AGENTS.md`, not this file.

> If this workspace is opened at a folder *above* `scripts/`, neither this file nor
> `.github/instructions/*.instructions.md` is auto-discovered: `copilot-instructions.md`
> is only detected in `.github/` at the **workspace folder root**. See
> `chat.instructionsFilesLocations` and `chat.useNestedAgentsMdFiles` in
> `../../.vscode/settings.json`.
