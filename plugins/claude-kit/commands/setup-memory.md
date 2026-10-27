---
description: Set up project memory - a project-specific CLAUDE.md and an AI_STATE.md, both tracked by git
---

Set up the memory files of the current project. Global rules (security, code quality, state handling) already come from `~/.claude/CLAUDE.md`: never copy them into the project.

1. **Inspect** the project: manifest files (`package.json`, `pyproject.toml`, `*.csproj`, ...), README, lint/test config, folder layout, CI files.

2. **Project `CLAUDE.md`** at the root.
   - Missing: draft it with project-specific facts only, under ~40 lines:
     ```markdown
     # <project name>
     <one line: what it is>

     ## Stack
     ## Commands
     <install, dev, lint, type-check, test, build: exact commands>
     ## Layout
     <key folders and what lives there>
     ## Conventions
     <naming, patterns, language of code/docs if not English>
     ## Gotchas
     <pitfalls, env vars needed (names only, never values)>
     ```
     Leave out any section you cannot fill from the files. Mark guesses with `(to confirm)`.
   - Present: do not rewrite it. Propose additions only, for missing commands or stack facts.

3. **`AI_STATE.md`** at the root, if missing, using the template of `/claude-kit:save-state` with:
   - Done: "Memory files initialized."
   - Current state: one line from step 1.
   - Next steps: "Awaiting instructions."
   - Open issues and Decisions: empty.

4. **Git tracking.** Run `git check-ignore CLAUDE.md AI_STATE.md`. If either is ignored, add `!CLAUDE.md` or `!AI_STATE.md` to `.gitignore`. Otherwise leave `.gitignore` alone.

5. **Show the drafts and wait for approval** before writing anything. Do not commit.
