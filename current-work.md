# Current Work

## Issue
ValueCell-ai/ClawX#1128 — [Bug]: 客户端界面出现正则表达式解析错误 (Invalid regular expression)

## Summary
When rendering long text with regex special characters in the chat UI, a SyntaxError is thrown because user content is passed to `String.match()` without escaping special characters. Stack trace points to a text highlighting/matching function that creates a regex from unsanitized user input.

## Status
find_work selected → moving to pr_gate
