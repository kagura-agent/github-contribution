# PR Review Feedback TODO

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

## Completed

## Completed
- [x] QwenLM/qwen-code #4456 — MERGED ✅ (was CHANGES_REQUESTED Round 2)
- [x] QwenLM/qwen-code #4474 — MERGED ✅ (was CHANGES_REQUESTED Round 2)
