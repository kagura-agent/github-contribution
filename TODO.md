
## QwenLM/qwen-code #4456 — CHANGES_REQUESTED (Round 2, 2026-05-27)
- [ ] Move `--list-extensions` handler AFTER `config.initialize()` (getExtensions() needs populated cache)
- [ ] Add `await runExitCleanup()` before `process.exit(0)`
- [ ] Guard `preconnectApi()` — skip when `--list-extensions` is set
- [ ] Rework tests to exercise real init → getExtensions flow (not mock past the bug)
- Priority: HIGH (reviewer waiting)

## QwenLM/qwen-code #4474 — CHANGES_REQUESTED (Round 2, 2026-05-27)
- [ ] Fix broken test mock in test 3 (cascading 7 test failures)
- [ ] Fix candidate-loop precedence: `~/.qwen/.env` should win over `~/.env` (more specific → higher priority)
- [ ] Fix tsc/eslint flagging `homeEnvPath` as unused
- Priority: HIGH (reviewer waiting)
