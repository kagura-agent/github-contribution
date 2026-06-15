# Current Work

## Issue
can1357/oh-my-pi#2612 — feat: Discover CLAUDE.md alongside AGENTS.md in ancestor path walk

## Design (agreed in issue comments)
- Always load (no config toggle)
- Both files when present, AGENTS.md first then CLAUDE.md (alphabetical)
- Same walk/skip/stop rules

## Implementation Plan

### Change List
1. **`packages/coding-agent/src/discovery/agents-md.ts`** — Change provider to scan for both `AGENTS.md` and `CLAUDE.md` during ancestor walk. For each directory level, check both filenames in order. Update PROVIDER_ID and DISPLAY_NAME to reflect broader scope.
2. **New test file or extend existing** — Add tests verifying:
   - CLAUDE.md alone is discovered
   - Both files at same level are loaded (AGENTS.md first)
   - CLAUDE.md at different depth than AGENTS.md
   - Hidden directory skip applies to CLAUDE.md too

### Implementation Method
- Use array `["AGENTS.md", "CLAUDE.md"]` and iterate per directory level
- Each found file gets its own `ContextFile` entry with same `level`, `depth`, `_source` handling
- Follow exact same pattern as current AGENTS.md handling (depth calculation, hidden dir skip, repo-root/home stop)
- Source meta uses existing `PROVIDER_ID` for all entries

### Boundary Cases
- Only standalone files (project root, ancestor dirs). `.claude/CLAUDE.md` is handled by `claude.ts` provider — no overlap since `agents-md.ts` skips hidden dirs (`baseName.startsWith(".")`)
- If AGENTS.md and CLAUDE.md both exist at same level, both are loaded (AGENTS.md first per alphabetical order)
- If only CLAUDE.md exists (no AGENTS.md), it still gets discovered
- Walk stops at `repoRoot` or `home` — same for both files
- Dedup handled by existing `context-file-dedup` logic if needed

### Test Strategy
- Check existing test patterns in `packages/coding-agent/test/discovery/`
- Add test cases for CLAUDE.md discovery using same test helpers
- Verify both-files-same-level ordering

### Risk Points
- Maintainer sign-off pending in issue comments (roboomp: "Holding for maintainer sign-off")
- PR may sit until can1357 approves the design
- Low technical risk — change follows existing patterns exactly

## Status
Plan phase — ready for review
