# Current Work

## Issue
can1357/oh-my-pi#3356 — Devin models silently fail with auto thinking (empty supported efforts)

## Summary
Devin provider models return empty response in TUI when thinking level is `auto` (default). Root cause: `clampAutoThinkingEffort()` returns effort as-is when `supported.length === 0`, but downstream `requireSupportedEffort()` throws because the effort isn't in the empty list. Fix: return `undefined` from `clampAutoThinkingEffort` when supported efforts is empty, matching `clampThinkingLevelForModel`'s behavior.

## Status
find_work selected → moving to pr_gate
