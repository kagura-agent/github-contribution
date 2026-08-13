# Workloop #8084 — offline fallback (2026-08-13 12:16 CST)

## Finder evidence

- [已验证] Capacity gate completed: `Assigned: 3 | Open PRs: 13`.
- [已验证] The wrapped finder exited `2` after its bounded tracked-repo scan emitted
  `scan_status status=124 timeout=true` / `scan_unavailable status=124 timeout=true`,
  and `FINDER_RESULT=UNAVAILABLE reason=tracked_scan status=124`.
- Durable redacted evidence: `offline/evidence/2026-08-13/20260813T121616+0800-find-work.md`.
  The partial scan tail ended at `EKKOLearnAI/hermes-web-ui` (the scan had just logged
  `scan-metric repo=modelcontextprotocol/inspector result=ok elapsed_ms=11017`).
- This is a discovery-unavailable boundary, not a verified empty queue, and not evidence
  of a network / auth / API-limit / OOM cause. No issue was selected from the partial output.

## Root-cause analysis (scan timeout is structural, not transient)

The finder wraps `gogetajob scan --all --skip-recent 12` under a 90s
`SCAN_TIMEOUT_SECONDS` ceiling (`tools/workloop-find-issue.sh` line 122). Verified facts:

- [已验证] `gogetajob` DB holds **90** tracked repos; **66** of them have
  `last_scanned_at` older than 12h (so `--skip-recent 12` does not skip them).
- [已验证] The active scan path is **serial** — `dist/cli/index.js` (bin entry
  `bin/gogetajob.js` → `dist/cli/index.js`) scans companies in a plain `for` loop with no
  concurrency. `dist/cli/commands/scan.js` (the parallel `--concurrency 3` + `pLimit`
  implementation) is **not imported anywhere** — dead/unwired code.
- [已验证] Per-repo cost ≈ 9–11s: `scan-metric ... elapsed_ms=11017` for one repo, and
  `last_scanned_at` advances roughly every 10s (04:15:01 → 04:16:14 = 8 repos in ~73s).
- [已验证] 66 repos × ~10s ≈ **11 minutes**, i.e. ~7× the 90s budget. The scan therefore
  times out after ~8 repos every run.
- [已验证] The cache fallback also failed: `finder-feed.json` `generated_at` is
  `2026-08-12T09:23Z` ≈ 19h old, past the 6h `FINDER_CACHE_MAX_AGE_SECONDS` (21600s) window.

`gogetajob scan` already ships the right knob: `--batch <n>` ("only scan the first N repos,
for cron/time-limited contexts"), applied **after** `--skip-recent` filtering and slicing the
stars-descending list (`dist/cli/index.js`: filter → `slice(0, batchSize)` → serial loop).
So `--batch 8` would bound each run to ~8 repos ≈ 80s, and combined with `--skip-recent 12`
the selection rotates through the full list across successive workloops (fresh repos get
skipped next run). The finder currently does not pass `--batch`.

## Follow-up classification

- [已验证] The one flagged PR comment (`kagura-agent/cove#487`) is a GitHub Actions
  `Preview deployed!` staging notice (`staging.cove.kagura-agent.com`), not actionable
  review feedback. Read directly via `gh pr view 487 --repo kagura-agent/cove --json
  comments,reviews`; no review, no change request, no reply required.
- The other 12 open PRs are `[them] waiting`. No CHANGES_REQUESTED / HARD_CLOSE /
  NEEDS_PING / CONFLICT / STALE_APPROVED. No GitHub write performed.

## Boundary

No candidate selection, code change, push, comment, issue, or PR action was performed after
the finder became unavailable. A later workloop must obtain a valid structured finder result
(or a validated ≤6h cache) before selecting contribution work.

## Next time (structural, not behavioral)

Apply the `--batch` bound (or a tunable `SCAN_BATCH_SIZE` env) to the finder's scan
invocation so discovery fits its own 90s ceiling; this is the recurring `find-issue-oom-fallback`
/ `finder-unavailable-evidence-boundary` class root cause, distinct from "handle the fallback
correctly" (which is already enforced).
