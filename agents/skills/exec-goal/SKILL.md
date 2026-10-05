---
name: exec-goal
description: >-
  Run an explicit persistent goal workflow that defines measurable success
  criteria, registers a mechanism that wakes or continues the same conversation,
  and repeatedly acts, verifies, and adjusts until the criteria pass. Use only
  when the user explicitly invokes exec-goal or asks for autonomous iteration
  toward a measurable target. Do not trigger merely because a task has a clear
  or verifiable end state. Do not use for routine implementation, debugging,
  planning, review, explanation, research, or single-pass fixes.
---
# Goal-Driven Execution

Use this only when the user explicitly invokes `exec-goal` or asks for
autonomous iteration toward a measurable target. Do not infer applicability
merely because a task has a verifiable end state. The defining requirement is
persistence: register a way to wake or continue the same conversation before
starting substantive work, then keep iterating until the verified goal is met.

## 1. Restate the goal

Say back, in one or two sentences, what outcome the user actually wants.
Ask before acting only when ambiguity affects authorization, risk, or success
criteria. Otherwise, state a reasonable assumption and continue; revisit it if
new evidence changes the interpretation.

## 2. Define success criteria

Write down concrete, checkable conditions that mean the goal is met. Good
criteria are observable:

- "Command X exits 0 and prints Y"
- "The new test fails on the old code and passes on the new code"
- "The page renders Z without console errors"

Weak criteria ("it works", "looks right") give you nothing to loop against. If
you cannot state a criterion you could verify, the goal is underspecified —
narrow it first.

## 3. Register a wake mechanism

Before substantive work, register one primary mechanism that can re-enter the
loop without a new user message. Prefer these mechanisms in order:

1. **Native goal mode.** Use the host's durable goal mechanism when available.
   Call the native goal-creation tool, or use `/goal` on interactive surfaces,
   with the objective and success criteria. Confirm that the goal is active
   before continuing.
2. **Active wait or monitor loop.** For work that can remain in the current turn,
   retain the process, session, or task handle and use its wait/resume mechanism.
3. **Trusted stop hook.** When native goals are unavailable, use an existing
   trusted hook that turns an attempted stop into a continuation prompt while
   the goal remains incomplete. Do not install or modify persistent hooks unless
   the user has authorized that configuration change.
4. **Same-conversation scheduled task.** For time-based or externally delayed
   work, schedule a return to the same conversation with the goal state and next
   verification step. Cancel or pause it when the goal finishes.

A sleep by itself, an untracked background process, or a context-free cron job
is not a wake mechanism. If no valid mechanism is available, do not claim
persistent execution; explain what is missing and request the mechanism or
authority needed to continue.

## 4. Loop: act -> verify

Take the smallest useful action toward the goal, then check it against the
criteria. Do not assume success — observe it (run the command, read the output,
exercise the flow). If a check fails, diagnose and adjust, then loop again.

Strong success criteria are what let you iterate on your own without asking at
every step. Do not emit a final answer merely because a turn, command, or waiting
period ended. Continue immediately, resume the retained task, or rely on the
registered wake mechanism to re-enter the loop.

## 5. Checkpoint

After each significant step, briefly note: what was done, what is verified,
what remains, which wake mechanism is active, and what event triggers the next
iteration. Don't continue from a state you can't describe back. If you lose
track of where you are against the criteria, stop and restate.

## 6. Stop only at a terminal condition

The task is done when every success criterion is observably met — not when the
steps are finished. State which criteria passed and how you checked each one.
Remove or cancel temporary wake mechanisms, then mark the goal complete. Do not
stop for a turn boundary, a failed attempt, or ordinary waiting. Stop early only
when the user pauses or cancels the goal, or when the host's rules classify the
goal as genuinely blocked. Report failures plainly; don't claim done on an
unverified criterion.
