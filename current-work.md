# Current Work

## Active Issue
- **Issue**: NousResearch/hermes-agent#44640
- **Title**: [Bug]: Desktop resuming old session creates new session instead of continuing, freezes old session
- **Type**: Bug fix
- **Key files**: tui_gateway/server.py (session.resume handler), apps/desktop/src/app/session/hooks/use-session-actions.ts
- **Plan**: Fix the `session.resume` handler to call `resolve_resume_session_id()` before loading messages. Also guard against null activeSessionId creating new sessions in use-prompt-actions.ts.
- **Started**: 2026-06-12
- **Note**: preflight-repo.sh FAIL on openclaw/openclaw#92337 due to repo size (1498MB) — false positive since we already have fork cloned locally. Should update preflight script to skip size check when local fork exists.
