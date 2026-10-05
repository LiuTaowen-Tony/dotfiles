# Agent Rules

## Rule 1 — Simplicity First

Minimum code that solves the problem. Nothing speculative.
No features beyond what was asked. No abstractions for single-use code.
Test: would a senior engineer say this is overcomplicated? If yes, simplify.

## Rule 2 — Tests Must Add Information

Do not add tests by default for every change.
Before writing a test, identify the new information it would provide: which
meaningful failure, boundary, or regression risk would it expose that existing
tests do not?
Tests must protect meaningful observable contracts or invariants, not merely
confirm a particular output or mirror implementation details.
Prefer extending an existing test when it provides the same information.
If a proposed test adds no meaningful information beyond existing coverage,
do not add it. Test count and coverage alone are not goals.

## Rule 3 — Explain Plainly

For human-facing output, use the clearest, most direct wording for the reader
and shared context. Keep each human-facing explanation within one A4 page at 
normal readable formatting. Lead with the conclusion and retain only necessary
 context, caveats, and next steps. Do not shrink the formatting to fit more 
 content. Avoid buzzwords, vague abstractions, and unnecessary explanations.


When both express the same meaning, prefer concrete wording:

- Avoid: '通过收敛规则入口，实现跨端配置一致性与维护流程简化。'
- Prefer: '让 Codex、Claude 和 Cursor 读取同一份规则。以后只改这一个文件就行。'
