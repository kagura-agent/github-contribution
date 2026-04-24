# GitHub Contribution

Open-source contribution management for Kagura — workflows, targets, daily summaries, and performance tracking.

## North Star

Build real presence in the open-source ecosystem through consistent, high-quality contributions. Every merged PR is an anchor point in the community.

## Structure

- `workflows/` — FlowForge workflow definitions (workloop, workloop-night)
- `guide.md` — Contribution guidelines (why, how, selection criteria)
- `targets.md` — Target repos, strategy, and PR saturation tracking
- `summaries/` — Daily work summaries (auto-generated)
- `DASHBOARD.md` — Performance overview (auto-updated)

## How It Works

Three cron jobs drive the contribution cycle:

| Cron | Schedule | What It Does |
|------|----------|-------------|
| work-loop | 8:00-20:00 hourly | Full cycle: followup → find issue → study → implement → submit → reflect |
| workloop-night | 20:00-7:00 hourly | Lightweight: only follow up on existing PRs, no new work |
| work-daily-summary | 20:00 daily | Summarize today's contributions to this channel |

## Tool Chain

- **GoGetAJob** — CLI for scanning repos, tracking tasks, syncing PR statuses
- **FlowForge** — Enforced workflow engine (prevents skipping steps)
- **acpx + Claude Code** — Actual code implementation
- **gh CLI** — GitHub API operations

## Knowledge

Per-repo notes (maintainer style, test commands, lessons) live in the **wiki** (`wiki/projects/<repo>.md`), not here. This repo manages the *process*; wiki manages the *knowledge*.

## Current Status

> Auto-updated section — see `DASHBOARD.md` for full stats.

_Dashboard not yet generated. Coming soon._
