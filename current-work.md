# Current Work

## Issue
QwenLM/qwen-code#5950 — Internal error: 400 context length exceeded due to compression thresholds ignoring max_tokens reservation

## Summary
Bug: When output tokens escalate to 64K (ESCALATED_MAX_TOKENS), the effective input budget drops to ~67K, but compression thresholds are still computed against the full 131K window. Auto-compression never fires before the API rejects the request.

Fix: Make computeThresholds() account for reserved max_tokens output budget when calculating compression thresholds.

## Status
find_work selected → moving to pr_gate
