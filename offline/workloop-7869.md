# Workloop #7869 — offline fallback (2026-08-09 08:02 CST)

## Finder evidence

- [已验证] Capacity gate completed: `Assigned: 2 | Open PRs: 18`.
- [已验证] The required wrapped finder invocation exited `2` with `FINDER_RESULT=UNAVAILABLE reason=tracked_scan status=124`. Its scanner tail recorded `scan_status status=124 timeout=true` followed by `scan_unavailable status=124 timeout=true`.
- [已验证] The redacted command/output artifact is `offline/evidence/2026-08-09/20260809T080524+0800-find-work.md`.
- Boundary: this is an unavailable tracked scan, not a valid empty feed and not evidence for a network, authentication, or API-limit cause.

## Existing PR hygiene

- [已验证] `git log --branches --not --remotes --oneline -20` in this repository returned no unpushed commits.
- [已验证] The pre-existing modified `workflows/workloop.yaml` was not staged or changed by this fallback.

## Offline module review — Cove draft/final delivery boundary

Read local source at `../cove/packages/plugin/src/dispatch.ts` and `dispatch-behavior.test.ts` (Cove commit `98e6f5d`).

- The dispatch path constructs a `createFinalizableDraftLifecycle` with a 250ms throttle. Preview sends are deduplicated by trimmed text, bounded by `COVE_TEXT_CHUNK_LIMIT`, and stop permanently after a REST send/edit failure.
- Final delivery uses `deliverWithFinalizableLivePreviewAdapter`: an active draft is finalized in place when possible; otherwise `freshSend` removes the draft before forwarding through `createCoveOutboundBridgeAdapter`.
- If the final outbound send throws, the final text is attached as `coveFinalPayload` to the error and logged as recoverable. This preserves recovery information without falsely claiming delivery.
- The behavior suite covers preview POST/PATCH, duplicate suppression, final in-place editing, fallback final sending, and recovery when fallback delivery fails. Future changes must preserve these observable boundaries rather than treating a green typecheck as sufficient evidence.

## Gradient review

- [已验证] Reviewed `beliefs-candidates.md` entries surfaced by the three-occurrence search. The finder-failure evidence rule is already encoded in the workloop's explicit `FINDER_RESULT=UNAVAILABLE → fallback_offline` branch; no candidate was promoted without independent V1–V3 evidence.
