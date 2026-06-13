# Current Work — 2026-06-13

## Issue
multica-ai/multica#4091 — TipTap autolink splits email addresses mid-input

## PR
https://github.com/multica-ai/multica/pull/4095 — CHANGES_REQUESTED

## Fix needed
Replace `linkifyjs` (transitive dep) with `detectLinks` from `@multica/ui/markdown/linkify` (internal utility).
3-line change: switch import, `match.value`→`match.text`, `match.href`→`match.url`, remove eslint-disable.

## Status
Addressing reviewer feedback (Bohan-J + feifeigood)
