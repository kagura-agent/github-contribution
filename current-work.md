# Current Work

## Issue
openclaw/openclaw#104951 — Heartbeat scheduler cadence decays after ~24h uptime

## Summary
Use fresh `Date.now()` at 4 post-`runOnce()` `advanceAgentSchedule()` call sites instead of stale `now` captured at run start. Prevents immediate refire when runOnce takes significant wall-clock time.

## Status
PR #105120 submitted ✅ — waiting for review
