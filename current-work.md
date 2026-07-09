# Current Work

## Issue
EKKOLearnAI/hermes-studio#1998 — Agent 正常結束後 session 的 ended_at/end_reason 未寫入數據庫，UI 永久顯示「思考中」

## Summary
Add `updateSession(ended_at, end_reason)` calls at three run termination points in `handle-bridge-run.ts` to properly mark sessions as complete when bridge runs finish.

## Status
PR #2004 submitted ✅ — waiting for review
