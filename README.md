# claude-kit

A personal, portable Claude Code setup: working rules, commands, skills and default references, kept in one Git repo and synced to every machine.

- **One source of truth** for `~/.claude/CLAUDE.md`, shared settings and a plugin (`claude-kit@workshop`).
- **Auto-sync**: a `SessionStart` hook pulls the repo and re-applies it each time Claude Code starts.
- **Safe by default**: preview before writing, backups before every change, credentials/history/projects never touched.

## What's inside

```
claude-kit/
├─ .claude-plugin/marketplace.json   marketplace "workshop"
├─ plugins/claude-kit/               the plugin "claude-kit"
│  ├─ commands/                      /add-rule, /load-state, /save-state, /setup-memory
│  └─ skills/                        references, humanizer, find-skills
├─ global/
│  ├─ CLAUDE.md                      global working rules (copied to ~/.claude)
│  ├─ settings.base.json             shared settings (merged into ~/.claude/settings.json)
│  └─ statusline-command.sh          status line script
└─ bootstrap.ps1                     sync script (preview by default)
```

## Requirements

| Tool | Why |
|---|---|
| Windows + PowerShell 5.1+ | runs `bootstrap.ps1` |
| Git (with Git Bash) | clone/pull; Claude Code runs hooks through Git Bash |
| Claude Code | obviously |
| GitHub CLI (`gh`), logged in | clone a private repo (`winget install GitHub.cli`, then `gh auth login`) |

## Install on a new machine

```powershell
# 1. Clone the kit (private repo: gh handles the auth)
gh repo clone Jeremie-pires/claude-kit $HOME\.claude-kit

# 2. Preview what would change (writes nothing)
& $HOME\.claude-kit\bootstrap.ps1

# 3. Apply
& $HOME\.claude-kit\bootstrap.ps1 -Apply
```

Then start Claude Code. The `claude-kit` plugin and the `workshop` marketplace are enabled by the merged settings; plugins are fetched on first launch.

### What `-Apply` changes

| File | Action |
|---|---|
| `~/.claude/settings.json` | **merged**: kit keys added, everything local kept (permissions are unioned, hooks appended) |
| `~/.claude/CLAUDE.md` | replaced by `global/CLAUDE.md` (previous file backed up) |
| `~/.claude/statusline-command.sh` | replaced (backed up) |

Never touched: `.credentials.json`, `history.jsonl`, `projects/`, any project-level `.claude/`.

## Updating

**Automatic**: every Claude Code launch runs `bootstrap.ps1 -Apply -Quiet` (fast-forward `git pull`, then re-merge). Offline or local changes → the pull is skipped and the local copy is used. Changes to `CLAUDE.md` and settings are read at the *next* session start.

**Manual**:

```powershell
& $HOME\.claude-kit\bootstrap.ps1            # preview
& $HOME\.claude-kit\bootstrap.ps1 -Apply     # apply
```

**Plugin only** (no bootstrap, e.g. on a shared machine), inside Claude Code:

```
/plugin marketplace add Jeremie-pires/claude-kit
/plugin install claude-kit@workshop
```

## Changing the kit

- **Add a rule**: `/claude-kit:add-rule <rule>`. Picks global vs project scope, checks conflicts, shows the diff, commits. Push when you confirm.
- **Add a command / skill**: drop a file in `plugins/claude-kit/commands/` or `plugins/claude-kit/skills/<name>/SKILL.md`, bump `version` in `plugins/claude-kit/.claude-plugin/plugin.json`, commit, push. Other machines pick it up at next launch.
- **Shared settings**: edit `global/settings.base.json`. Keep it free of absolute paths and project-specific blocks.

Work on the clone in `~/.claude-kit` so there is a single working copy.

## Rollback

Each change to `settings.json` keeps a `settings.json.bak-<timestamp>` (last 5) in `~/.claude`; `CLAUDE.md` and the status line script get `.bak-<timestamp>` copies too. To disable auto-sync, remove the `SessionStart` hook that calls `bootstrap.ps1` from `~/.claude/settings.json`.

## Security notes

- The auto-sync hook **executes `bootstrap.ps1` from this repo** at each launch: anyone with write access to the repo can run code on your machines. Keep the repo private and enable 2FA.
- Default permissions in `global/settings.base.json`: `git push` asks first; force-push, `reset --hard`, `clean -f`, `branch -D`, `rm -rf` and reading `.env*` files are denied. These rules target the Bash tool.
- Never commit secrets. Secrets live in `.env` files or user environment variables.
- Third-party plugins (`agent-skills`, `caveman`) were reviewed at install time; re-check them after major updates.

## Troubleshooting

| Symptom | Check |
|---|---|
| Hook doesn't run | `~/.claude/settings.json` has the `SessionStart` entry; `powershell` is on PATH; run `bootstrap.ps1` by hand to see the error |
| `clone failed` | `gh auth status`; the private repo needs your login |
| `/claude-kit:add-rule` not found | plugin not installed yet: run the bootstrap, restart Claude Code, check `/plugin` |
| Settings differ from the kit | expected: local keys are kept; only kit keys are overwritten |

## Sharing / forking

Replace the repo path `Jeremie-pires/claude-kit` in `bootstrap.ps1` and `global/settings.base.json` with yours, review `global/CLAUDE.md` and the permissions, then follow the install steps above.
