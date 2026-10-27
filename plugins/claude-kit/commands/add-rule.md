---
description: Add a working rule to the global kit CLAUDE.md or the project CLAUDE.md, with conflict check and diff approval
argument-hint: "[--global|--project] <rule in plain words>"
---

Add this rule: $ARGUMENTS

If no rule text was given, ask the user for it and stop. (Session-based suggestions are not available yet.)

Follow these steps strictly, in order:

1. **Locate files.**
   - Global source of truth: `~/.claude-kit/global/CLAUDE.md`. If it does not exist, use `~/.claude/CLAUDE.md`.
   - Project file: `CLAUDE.md` at the project root.
   Read both.

2. **Pick the scope.** `--global` or `--project` forces it. Otherwise: valid for any project → global; mentions a stack, tool, path or convention of this repo → project. If unclear, ask the user.

3. **Refuse** and explain if the rule contains a secret (key, token, password), is too vague to be actionable ("write good code"), or is about current state / progress (that belongs in `AI_STATE.md`, never here).

4. **Check conflicts.** Compare with existing rules in both files. If it duplicates one, say so and stop. If it contradicts one, show both and ask: replace, keep, or scope as an exception.

5. **Write the rule**: one imperative line, English, no filler. Place it in the matching section (create a section only if none fits).

6. **Size check.** If the global file would exceed ~80 lines, propose condensing existing rules or moving one into a skill instead of adding.

7. **Show the exact diff and wait for approval.** Write nothing before the user says yes.

8. **Apply, then commit** in the repo that owns the file (kit repo for global, project repo for project) with message `docs(rules): <short summary>`. Stage only that file. Do NOT touch `AI_STATE.md`.

9. **Push only if the user confirms.** Never force-push.

10. Report in one line: file changed, scope, commit hash. For a global rule, remind that `~/.claude/CLAUDE.md` is refreshed at the next session start (bootstrap); apply the rule now in this conversation anyway.
