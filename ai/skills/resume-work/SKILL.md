---
name: resume-work
description: >-
  Pick a previously suspended body of work back up — read the project's
  suspended-work manifest, load the chosen "start here" scratchpad, verify the
  workspace still matches, and summarize where things stand. Use when Jason
  says "resume work", "pick that work back up", or asks what he has suspended.
  Loads context only; it starts no work of its own.
disable-model-invocation: true
---

# Resume Work

This skill is **user-invoked only** (`disable-model-invocation: true`). Named
`resume-work` rather than `resume` because `/resume` is a built-in Claude Code
command.

Counterpart to `/suspend`. It rehydrates **context and nothing else** — no
re-spawning agents, no restarting processes, no picking up the next step. It
ends by handing Jason a summary and waiting.

Best run in a fresh session, which is the situation it exists for.

## 0. Preconditions

`whoami` must return a Solo `process_id`. If not, stop and say so.

## 1. Find the manifest

`scratchpad_list` with tag `manifest`, falling back to a name query for
`Suspended Work`. If there isn't one, nothing has ever been suspended in this
project — say so and stop.

## 2. Choose the body of work

Read the manifest. If Jason named a body of work when invoking the skill,
match it. Otherwise show the rows — title, branch, when it was suspended, next
step — and ask which he wants, using the multiple-choice picker. Include
`active` rows: they're work he resumed and may have drifted away from without
re-suspending.

If there's exactly one suspended row, still confirm before loading it.

## 3. Load the context

`scratchpad_read` the linked start-here scratchpad in full. **Remember its
id for the rest of this session** — a later `/suspend` updates this same
document rather than creating a duplicate.

Then read what it points at:

- The scratchpads listed under `Related scratchpads`, or anything tagged with
  the slug via `scratchpad_list`.
- The files under `Key files`, enough to ground yourself.

## 4. Verify the workspace still matches

Compare the `Workspace` section against reality. Report mismatches; don't
silently fix them.

```bash
pwd
git -C "$REPO" rev-parse --abbrev-ref HEAD
git -C "$REPO" worktree list
git -C "$REPO" status --short
```

Things worth flagging:

- Wrong directory or branch → tell Jason the `cd` / `git checkout` he needs.
  Don't switch for him; he may have another body of work checked out here.
- Worktree gone → the work may have been finished or cleaned up. Say so and
  ask before recreating anything.
- The recorded PR merged or closed since suspending (`gh pr view <n> --json
  state`) → the next steps in the scratchpad may be stale.
- Uncommitted changes that differ from what was recorded → something moved
  since suspending.

Also check whether the shared processes the scratchpad recorded are still
running (`list_processes`). Report which aren't. Don't restart them.

## 5. Mark the manifest row active

`scratchpad_read` the manifest for its revision, then `scratchpad_edit` to
flip this work's row to `active` with today's date. The row stays — it's how
Jason spots work he picked up and wandered away from again. Only
`/finish-work` removes rows.

## 6. Summarize and stop

Give Jason:

- The goal and where things stand, in a few lines.
- The next steps from the scratchpad.
- Any workspace mismatch from section 4, called out clearly.
- Open questions the scratchpad recorded for him.
- Which agents were running when it was suspended, so he can decide what to
  re-spawn.

Then **stop and wait**. Don't start on the next step, don't spawn agents,
don't restart processes — even when the next step is obvious. Jason directs
from here.
