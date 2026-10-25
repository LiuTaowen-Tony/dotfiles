# Agent Rules

## Rule 1 — Simple, Readable Code

Except for throwaway code that is not kept, design and write code, in any language,
as if every line will get a Google-level code review. That reviewer rejects code
that is not needed and code that is hard to follow.

- Scope: the minimum code that solves the problem. Nothing speculative, no features
  beyond what was asked.
- Structure: layers, each with one clear job, that the layer above reuses and
  combines: lower layers wrap a mechanism, higher layers use them to do the task.
  Each layer exposes a typed API; the layer above never reaches into its internals
  or assembles command lines for it. A layer or abstraction needs a separate job or
  a second user; otherwise inline it.
- Lines: one statement per line. Name intermediate values instead of nesting calls.
  Names say exactly what a thing is or does. Comments do not restate what the code
  does; they say why it does it.

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
and shared context. By default, keep each explanation within one A4 page at
normal readable formatting. Longer responses are appropriate for comprehensive
discussion summaries, complex research explanations, or explicit requests for
detail when the extra space is needed to preserve reasoning, evidence, and
important distinctions. Lead with the conclusion and retain only necessary
context, caveats, and next steps. Do not shrink the formatting to fit more
content. Avoid buzzwords, vague abstractions, and unnecessary explanations.


When both express the same meaning, prefer concrete wording:

- Avoid: '通过收敛规则入口，实现跨端配置一致性与维护流程简化。'
- Prefer: '让 Codex、Claude 和 Cursor 读取同一份规则。以后只改这一个文件就行。'
