---
name: pause-and-report
description: Pause ongoing work and report the current task's progress. Use when the user asks to pause or stop what you are doing and explain where things stand. A status-only request does not authorize pausing work unless this skill is explicitly invoked.
---

# Pause and Report

Pause the current task before reporting. Do not complete one more implementation
step, edit files, or run tests just to make the progress update look better.

Stop starting new work. Use available controls to pause task-related persistent
goals, automatic continuations, and background agents. Do not create a new goal
or schedule, discard work, or stop unrelated processes. If an operation cannot
be safely interrupted, report that it is still running and do not start its
next step. Do not claim work is paused while it can still continue automatically.

Use the conversation and observed results. Make only minimal read-only status
checks when needed to avoid reporting stale information; do not restart the
investigation.

Give a short, plain-language update covering what matters:

- What the task is trying to achieve and where it currently stands.
- What is completed and verified; distinguish changes made but not yet checked.
- Anything still running, waiting, or blocked.
- What remains and the next action when work resumes.

Do not invent a completion percentage or present a plan as completed work.
Keep the update within one A4 page at normal readable formatting.

After reporting, wait for the user to ask you to continue. Do not resume the
task automatically or treat a follow-up status question as permission to resume.
