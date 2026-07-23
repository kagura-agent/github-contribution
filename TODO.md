# PR Review Feedback TODO

## NVIDIA/NemoClaw #7434 — fix(agents): merge separate --provider/-m flags into combined form

**Status (2026-07-23 20:19)**: OPEN, MERGEABLE. CodeRabbit review with 2 actionable comments. No human review yet.

### [P2] Handle end-of-options delimiter `--` in argv rewriting
- **File**: `@agents/hermes/hermes-wrapper.py` line 473-475
- **Issue**: Loop should stop rewriting when it encounters `--`, returning original argv immediately so all following tokens remain opaque/unchanged.
- **Action**: Add `--` guard + integration test covering provider/model-looking arguments after `--`.

### [P2] Move CI prerequisite assertion out of skipped suite
- **File**: `@test/hermes-wrapper-provider-merge.test.ts` line 22-28
- **Issue**: CI prerequisite assertion is inside the `describe.skipIf` suite so it never executes when skipped. Should assert before suite eval so CI fails properly when `canRun` is false.
- **Action**: Restructure test file assertion ordering.

---

## QwenLM/qwen-code #5957 — fix(core): subtract reserved output tokens from context window

**Status (2026-06-28 22:30)**: CHANGES_REQUESTED Round 2 by wenshao (12:43 UTC). Critical design flaw identified.

### [P0] Fix reservedOutputTokens sourcing — params.config.maxOutputTokens is undefined in interactive flow
- **Root cause**: `turn.ts:376` calls `chat.sendMessageStream(model, { message, config: { abortSignal } })` — no `maxOutputTokens` in config. So `params.config?.maxOutputTokens ?? 0` = 0, making both auto and hard threshold subtractions no-ops.
- **Real output budget sources**: `samplingParams.max_tokens` (user/env override) or `ESCALATED_MAX_TOKENS` (escalation ceiling). NOT `params.config.maxOutputTokens`.
- **Fix approach**: Derive reserve from actual output budget — `Math.max(ESCALATED_MAX_TOKENS, tokenLimit(model, 'output'))` when no user override, else `samplingParams.max_tokens`.
- **Test gap**: Current 4 tests inject `reservedOutputTokens` directly into `service.compress()`, bypassing the real call chain. Need `sendMessageStream`-level integration test.
- **Reply posted**: 2026-06-28 14:32 UTC acknowledging issue, committing to v2.

---

## openclaw/openclaw#96651 — fix(memory-core): recover primary embedding provider after transient outage

**Status (2026-06-25 12:10)**: ClawSweeper review at 03:34 UTC — verdict `needs-human`, blocked until fixes + proof.

### [P1] Disable fallback when probing primary recovery
- File: `extensions/memory-core/src/memory/manager-sync-ops.ts:2688`
- Issue: `primaryRequest` carries configured fallback. If primary still down but local fallback succeeds, `createEmbeddingProvider` returns provider with `fallbackFrom`; code then clears fallback state incorrectly.
- Fix: Pass `fallback: "none"` to recovery probe OR reject result when `primaryResult.fallbackFrom` is set.

### [P1] Fix TypeScript errors in recovery test harness
- File: `extensions/memory-core/src/memory/manager-provider-recovery.test.ts:56-57`
- Issue: TS2416 (providerLifecycle override type mismatch) + TS2445 (protected member access)
- Fix: Type harness as `MemoryProviderLifecycleState`, expose setter for lifecycle setup

### [P0] Add real behavior proof
- Need redacted terminal output/logs showing memory_search fallback during outage and recovery after primary returns
- After fixing code, generate proof from local test run

---

## openclaw/openclaw#92665 — fix(llm): honor cacheRetention for LiteLLM-proxied Anthropic models

**Status (2026-06-18 06:30)**: clawsweeper re-review at 22:23 UTC kept verdict `needs-human` — my P1 fix at c3001b9d is incomplete.

### [P1] Preserve explicit cache gate through `getCompat()`
- File: `src/llm/providers/openai-completions.ts:1323` (`getCompat()`)
- Issue: I added `requiresExplicitCacheConfig` to `ResolvedOpenAICompletionsCompat` (detected in `detectCompat`), but `getCompat()` rebuilds compat whenever `model.compat` exists and does **not** preserve this internal flag
- Fix: Carry `requiresExplicitCacheConfig` through `getCompat()` compat-merge path
- Regression test: Add case for LiteLLM Claude model with `model.compat` override + no `cacheRetention` → must NOT emit `cache_control`

### [P3] Update LiteLLM docs
- File: `docs/providers/litellm.md` (currently says proxy gets no prompt-cache hints — now inaccurate after this PR)

### 🔴 CI Regression — checks-node-agentic-plugin-sdk failing
- Run: https://github.com/openclaw/openclaw/actions/runs/27722346620/job/82010670717
- Test: `src/plugin-sdk/provider-catalog-shared.test.ts:189,214` — `supportsNativeStreamingUsageCompat` returns `false`/`undefined` for qwen `dashscope.aliyuncs.com` URL (expected `true`)
- 13 Jun CI on this branch was green; 17 Jun CI (after c3001b9d) failed
- **Mystery**: c3001b9d diff only touches `openai-completions.ts/test.ts` + `anthropic-family-cache-semantics.ts/test.ts`. plugin-sdk test files identical to upstream/main (where test passes). Likely indirect type/build interaction — needs investigation
- Workloop action: reproduce locally on c3001b9d, bisect against 78d91256 (previous PR commit) to confirm regression source

---

## NVIDIA/NemoClaw #5924 — inference set error message improvement

**Status (2026-06-29 10:13)**: Assigned to kagura-agent. Ready to implement.

### Task
- Improve error message when `nemoclaw inference set` is used with unregistered provider
- Show list of registered providers + hint to run `nemoclaw onboard`
- Volunteered 2026-06-28, assigned same day

---

## Completed
- [x] QwenLM/qwen-code #4456 — MERGED ✅ (was CHANGES_REQUESTED Round 2)
- [x] QwenLM/qwen-code #4474 — MERGED ✅ (was CHANGES_REQUESTED Round 2)

---

## QwenLM/qwen-code #6104 — fix: lazy-load memory prompt when indexes are empty

**Status (2026-07-01 20:10)**: CHANGES_REQUESTED Round 3 by wenshao (automated, 11:32 UTC). 4 Critical findings.

### [P0] Critical 1: Condensed save section missing maintenance directives
- condensed path omits 4 directives from full protocol: name/description/type sync, semantic organization, remove stale memories, cross-directory dedup
- Fix: include these in condensed save section

### [P0] Critical 2: No logging for condensed vs full path decision
- Every other file in memory/ uses createDebugLogger. This function (consequential branching) has no trace.
- Fix: Add debug logger call at the branch point

### [P0] Critical 3: condensedDoNotSave drifts from WHAT_NOT_TO_SAVE_SECTION
- Hand-written paraphrase with concrete differences (drops "conventions", "project structure")
- Fix: Derive condensed version from shared code/constants

### [P1] Critical 4: appendToUserMemory missing BuildMemoryPromptOptions param
- Public API wrapper doesn't forward new options parameter
- Fix: Add optional options param to appendToUserMemory

**Action**: workloop code fix needed. Claude Code assignment.
