# PR Review Feedback TODO

## [System] slow-repo scan timeout blocks find_work (multi-repo, structural)

**Observed**: `gogetajob scan --all` hard-times out (`status=124`) on a single slow repo and forces `FINDER_RESULT=UNAVAILABLE` → fallback_offline for the whole round. Recurring across repos:
- 2026-08-13 (AM): camel-ai/oasis (~198MB, near 200MB threshold, guide rule #20)
- 2026-08-13 (PM): langwatch/langwatch

**Action**: Make the scan wrapper skip/tolerate slow repos instead of hard-timeout (per-repo timeout + continue), or add a skip-list for known-slow repos. This is the structural fix behind DNA recidivism `find-issue-oom-fallback` / `finder-unavailable-evidence-boundary`.

---

## [System] finder ignores blocklist → blocklisted repos starve the feed

**Observed (2026-08-13 16:30 CST)**: `workloop-find-issue.sh` 的 7 个 gate 不检查 `gogetajob blocklist`。blocklisted 高⭐ repo（openclaw 384K / hermes 200K / opencode 189K）持续占据 feed 前列，`MAX_CHECK=15` + 3 survivor 提前 stop，饿死 P3 新项目（本轮刚加入的 lmnr/pipelex 因 `--skip-recent 12` 也未进 feed）。结果：find_work 反复推荐 blocklisted openclaw 的 3 个 issue（#114081 竞争 PR / #114084 not-repro-on-main / #114049 设计阶段），造成 find_work→discover 多轮循环。

**Action**:
1. 在 `workloop-find-issue.sh` 的 gate 列表加 blocklist 检查（命中 `gogetajob blocklist` 即跳过该 repo）。
2. 调和 guide.md P1 表（仍列 openclaw 为 P1）与 blocklist（openclaw 已 blocklisted「8 consecutive weeks of violations, high rejection rate, bot-reviewed only」）的矛盾——需 Luna 确认是否降级 openclaw。
3. 顺带核查 `gogetajob discover --topic` 参数疑似不生效（返回泛 help-wanted repo 而非 topic 过滤结果，`--keywords` 才有效）。

---

## langwatch/langwatch #6432 — satisfy reviewer’s duplicate-reactivation coverage requirement

**Status (2026-08-09 22:10 CST)**: `drewdrewthis` review remains `CHANGES_REQUESTED`; Kagura’s 2026-08-04 replies have no subsequent reviewer response. The requested fix is a code/test follow-up, not suitable for the patrol run.

**Action**: In the next workloop, read the linked inline review and add behavior-level coverage for duplicate/already-active webhook delivery, proving `endDate` is cleared while `startDate` is omitted; then run the focused billing tests and update the PR.

---


## kagura-agent/NemoClaw — release-target label workflow has no usable release tag

**Observed (2026-08-09 22:10 CST)**: Scheduled workflow “Automation / Label Merged PR Release Target” failed in runs #107, #108, and #109. Run #109 logs explicitly report `No strict semver release tags were found` from `loadReleaseTags()`.

**Action**: Decide whether the repository should have an annotated strict `vMAJOR.MINOR.PATCH` release tag or whether the workflow must gracefully skip repositories with no releases; implement and test the chosen behavior in a dedicated workloop.

---


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

---

## [CI] QwenPaw Full Tests Nightly — ✅ RESOLVED 2026-08-16 (fork sync)

**Observed (2026-08-15 06:1x CST via github-patrol)**: run 31832504935 (08-14) + 5 prior nights all fail.
- Failing test: `tests/integration/test_plugins.py::test_plugins_catalog_returns_200_with_plugins_field_contract`
- `GET /api/plugins/catalog` → 500; test documents fallback `{"plugins": [], "error": ...}` when CDN unreachable

**Root cause (2026-08-16 triage, run 31902167198 log)**: fork main was **372 commits behind upstream** (d0b9194d, 07-10 vs upstream 59f2849, 08-16; `ahead_by: 0`). CDN returns gzip-encoded catalog; fork's `_fetch_json` did `decode("utf-8")` → `UnicodeDecodeError: byte 0x8b` (gzip magic) → 500. **Upstream already fixed this** (`Accept-Encoding: gzip` + `gzip.decompress` in download_catalog.py). Not a fork-specific bug — a stale-fork artifact. Earlier attribution to upstream issue #6782 was wrong (that's a docker plugin-market UX issue).

**Fix applied**: `gh api -X POST repos/kagura-agent/QwenPaw/merge-upstream -f branch=main` → fast-forwarded to 59f2849 (identical to upstream). Verified gzip fix present in fork main. Manually triggered nightly run 31949852366 (08-16 13:27Z) to verify. Upstream's own nightly also fails on e2e 45min timeout (pre-existing, unrelated).

## [CI] NemoClaw Label Merged PR Release Target — fails on merge events

**Observed (2026-08-15 06:1x CST)**: 2 failures today (13:46Z, 19:16Z, run 31832491691): `Error: No strict semver release tags were found` — repo has ZERO tags/releases. Workflow `label-merged-pr-release-target.yaml` calls `loadReleaseTags()` which throws when no semver tags exist. Fix options: (a) create initial release tag, (b) make workflow tolerate no-tags state.

## [CI] opencode fork close-prs — 403 on comment creation

**Observed (2026-08-15 06:1x CST)**: run 31845699331 (dev branch, 22:12Z 08-14): script/github/close-prs.ts fetched 1279 PRs, matched 6 to close, but `POST /repos/.../issues/{n}/comments` → 403 "Resource not accessible by integration". Previous nightly runs (08-12, 08-13) succeeded. Likely GITHUB_TOKEN permission gap when commenting on specific PRs (e.g. fork PRs). Check whether a newly opened fork PR triggered it.
