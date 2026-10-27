---
description: Update AI_STATE.md with this session's progress (keeps the decisions log)
---

Update `AI_STATE.md` at the project root from this session's work. Create it if missing.

Use exactly these sections:

```markdown
# Project state
_Updated: <YYYY-MM-DD>_

## Done
- <short, factual bullets for the current milestone>

## Current state
<architecture and code state in a few lines: what works, what is stubbed>

## Next steps
1. <exact next action>

## Open issues
- <known bugs, blockers, open questions>

## Decisions
- <YYYY-MM-DD> <decision> — <why>
```

Rules:
- Rewrite every section except "Decisions". Append new decisions to "Decisions"; never delete or rewrite existing entries.
- "Done" covers the current milestone only. Drop items that no longer help to resume work.
- Whole file under 500 words. If "Decisions" grows past ~20 entries, propose moving the oldest ones to `docs/decisions.md`.
- Facts only, full sentences where needed, no filler, no caveman style. No secrets, tokens or credentials.
- Do not commit. Report in one line what changed.
