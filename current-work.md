# Current Work

## Issue
openclaw/openclaw#109638 — sessions_yield deadlock: stripSessionsYieldArtifacts leaves trailing assistant messages blocking auto-announce

## Summary
Extend stripSessionsYieldArtifacts() to also strip trailing regular assistant messages after yield artifact removal. Prevents deadlock when sub-agent completion tries to inject continuation.

## Status
PR #109806 submitted ✅ — waiting for review
