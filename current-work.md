# Current Work

## Issue
can1357/oh-my-pi#3378 — Add advisor.minSeverity config to filter advisories by severity level

## Summary
Enhancement: add `advisor.minSeverity` config option (nit|concern|blocker) to deterministically filter advisories by severity before injection into main agent context. Currently only WATCHDOG.md soft guidance exists. The runtime already parses severity tags in advisory XML — just need a comparison before injection.

## Status
find_work selected → moving to pr_gate
