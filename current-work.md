# Current Work

## Issue
MoonshotAI/kimi-code#972 — [Bug/Web]Web前端LaTeX公式渲染不正确

## Summary
In the kimi-code web frontend (`kimi web`), LaTeX formula rendering is broken. Different LaTeX delimiters (like $, $$, \( \), \[ \]) are not properly handled — blue highlighted text appears where it shouldn't, and formulas don't render correctly. Clear reproduction: use `kimi web`, prompt model to output E=mc² with different delimiters, observe rendering errors.

## Status
find_work selected → moving to pr_gate
