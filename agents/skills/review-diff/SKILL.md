---
name: review-diff
description: Prepare uncommitted changes so the user can review them in the VS Code Source Control view (or plain git diff) before anything is committed. Use when the user asks to show, prepare, or set up a diff for review, or to split changes into parts to review. Does not commit.
---

# Review Diff

Lay out the working tree so each part of the change reads cleanly in VS Code's
Source Control view: "Staged Changes" holds one part, "Changes" the other. Do
not commit, push, or discard anything; the user decides after reviewing.

## Steps

1. **Inspect.** `git status --short` and `git diff --stat`; read the diffs. Group
   the hunks into at most two logical parts, the mechanical or preparatory part
   first (renames, removals, call-site updates) and the substantive part second.
   With more than two parts, ask whether to use a review branch with one commit
   per part instead.
2. **Clean up before showing.** Fix stale docs, docstrings, and readers of
   changed formats that the change leaves wrong, so the reviewer does not trip on
   them. Say what you changed.
3. **Stage part 1.**
   - Files only in part 1: `git add <files>`.
   - Files with hunks from both parts: build the part-1 version (start from
     `git show HEAD:<path>` and apply only part 1's edits), check that it parses
     or builds, then stage it without touching the working file:
     `git update-index --cacheinfo 100644,$(git hash-object -w <tmpfile>),<path>`.
   - Never use interactive staging (`git add -p`, `-i`).
4. **Leave part 2 unstaged.** Mark new files with `git add -N <files>` so they
   show as diffs rather than untracked files. Check `git check-ignore -v` for
   data or outputs the docs refer to; ignored files will not be in the diff.
5. **Verify.** `git diff --cached --stat` is exactly part 1 and `git diff --stat`
   is exactly part 2; the staged versions of mixed files parse
   (`git show :<path>`).

## Report to the user

- Where to look: VS Code Source Control, "Staged Changes" = part 1, "Changes" =
  part 2; or `git diff --cached` and `git diff`.
- Per part: what it does, size (files, +/-), and whether it is mechanical.
- For the substantive part: the reading order (definitions and constants first,
  then the core function, then callers) and the places most likely to be wrong.
- Any data the reviewer can check against, with the command.
- Open decisions, and that nothing is committed yet. Offer to commit the parts
  separately once reviewed.
