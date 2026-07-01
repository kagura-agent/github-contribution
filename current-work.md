# Current Work

## Issue
NVIDIA/NemoClaw#6052 — openshell policy get --full output cannot be used directly with policy set — metadata header causes YAML parse failure

## Summary
The `openshell policy get --full` output includes metadata header lines (Version, Hash, Status, Active, Created, Loaded) before actual YAML. Adding a `nemoclaw sandbox policy get` command that strips metadata and outputs clean YAML.

## Status
PR #6122 submitted ✅ — CI green, CodeRabbit review addressed, waiting for maintainer review
