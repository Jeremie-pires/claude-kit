# Project state
_Updated: 2026-10-27_

## Done
- Public-readiness pass (repo still private, nothing pushed): 7 commits from `f6ef77e` to `c531969` on `main`.
- `bootstrap.ps1` derives the `workshop` marketplace from the clone's `origin`; `-Repo` has no default and is only used for a first clone.
- Plugin renamed `claude-kit` to `toolkit` (folder, manifests, `enabledPlugins`, command references). `marketplace.json` has `renames: { "claude-kit": "toolkit" }`. The bootstrap drops the old `enabledPlugins` key and uninstalls `claude-kit@workshop` only after `toolkit@workshop` is installed.
- `global/CLAUDE.md` replies in the user's language; personal overrides go in `~/.claude/rules/` (created `personal.md` on this machine only: French, French resume triggers).
- MIT `LICENSE` (Jeremie-pires); upstream MIT license added to `skills/find-skills` (vercel-labs/skills); plugin metadata filled in.
- README rewritten for forks: quick start, commands table, "Make it yours", sync details, uninstall, security, AI-agent runbook, credits. No company or gateway mentions remain.
- Checks: `claude plugin validate .` passes (only the intentional missing-`version` warning); secret scan of the tree and token-format grep of the git history found nothing.

## Current state
Marketplace `workshop` (`.claude-plugin/marketplace.json`) lists one plugin, `toolkit` (`plugins/toolkit/`: 4 commands, 3 skills). `global/` holds the rules, `settings.base.json` and `statusline.js`. `bootstrap.ps1` (preview by default, `-Apply` to write) merges settings, syncs `CLAUDE.md` and `statusline.js`, installs missing plugins, and runs from an async `SessionStart` hook. The new bootstrap was only run in preview mode; this machine still has `claude-kit@workshop` installed and `~/.claude` not yet re-applied.

## Next steps
1. Push `main`, then run `& $HOME\.claude-kit\bootstrap.ps1 -Apply` (after `git pull` in `~/.claude-kit`) and restart Claude Code; confirm `/toolkit:load-state` works and `claude-kit@workshop` is gone.
2. Recreate `~/.claude/rules/personal.md` on each other machine.
3. Start the mods exploration: spec a `tool.call` mod hardening the Bash deny rules (catches `/bin/rm -rf`, `bash -c "..."`), as a second plugin in `workshop`.

## Open issues
- Before going public: enable 2FA on the personal GitHub account (sole collaborator; the sync hook trusts whoever can push).
- Windows only (PowerShell bootstrap); the plugin itself is OS-independent.
- GitHub repo is still named `claude-kit`; renaming it is optional and would change the clone URL.

## Decisions
- 2026-10-27 Plugin name `toolkit` — `claude-` prefix is reserved for Anthropic; keeps the "kit/toolbox" idea.
- 2026-10-27 Distribution by fork — the sync hook executes repo code, so each user must run code from a repo they control.
- 2026-10-27 Personal preferences in `~/.claude/rules/` — loaded in every project without prompt and never touched by the kit.
- 2026-10-27 MIT license under the GitHub handle `Jeremie-pires` — permissive, compatible with bundled MIT skills.
- 2026-10-27 No `version` in `plugin.json` — the plugin tracks commits, no bump needed.
- 2026-10-27 Keep `~/.claude-kit` path and `claude-kit-sync.json` names — avoids migrating files on existing machines.
