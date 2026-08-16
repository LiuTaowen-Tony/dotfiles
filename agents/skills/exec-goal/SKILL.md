---
name: exec-goal
description: >-
  Goal-driven execution for tasks with a definable end state. Use when the task
  has a verifiable "done" condition and you should loop until it's met rather
  than following a fixed list of steps. Restate the goal, define explicit
  success criteria, then iterate act -> verify until the criteria pass.
---
# Goal-Driven Execution

Use this when a task has a real end state you can check, not just a sequence of
steps to perform. The point is to define what "done" means up front, then loop
independently toward it — steps are a means, the verified goal is the target.

## 1. Restate the goal
Say back, in one or two sentences, what outcome the user actually wants. If the
goal is ambiguous or has multiple reasonable interpretations, stop and ask
before starting (see Rule 1). A vague goal produces vague success criteria.

## 2. Define success criteria
Write down concrete, checkable conditions that mean the goal is met. Good
criteria are observable:

- "Command X exits 0 and prints Y"
- "The new test fails on the old code and passes on the new code"
- "The page renders Z without console errors"

Weak criteria ("it works", "looks right") give you nothing to loop against. If
you cannot state a criterion you could verify, the goal is underspecified —
narrow it first.

## 3. Loop: act -> verify
Take the smallest useful action toward the goal, then check it against the
criteria. Do not assume success — observe it (run the command, read the output,
exercise the flow). If a check fails, diagnose and adjust, then loop again.

Strong success criteria are what let you iterate on your own without asking at
every step.

## 4. Checkpoint
After each significant step, briefly note: what was done, what is verified,
what remains. Don't continue from a state you can't describe back. If you lose
track of where you are against the criteria, stop and restate.

## 5. Stop when verified
The task is done when every success criterion is observably met — not when the
steps are finished. State which criteria passed and how you checked each one.
Report failures plainly; don't claim done on an unverified criterion.
