---
name: finish-work
description: >-
  Tear down a finished body of work — close its agents, remove its sandbox and
  worktree, archive its scratchpads, and drop it from the suspended-work
  manifest. Confirms every group before acting. Use when Jason says "I'm done
  with this", "finish this work", "clean this up", or "this one's shipped".
  Works whether or not the work was ever suspended.
disable-model-invocation: true
---

# Finish Work

This skill is **user-invoked only** (`disable-model-invocation: true`) — it
deletes worktrees and closes agents, so it runs when Jason types
`/finish-work`, never on Claude's own initiative.

Counterpart to `/suspend` and `/resume-work`, but it doesn't depend on either:
it finishes any body of work, suspended or not. Work that *was* suspended gets
its start-here scratchpad archived and its manifest row removed too.

**Discover everything first, confirm, then act.** Nothing is torn down until
Jason has ticked it.

## 0. Preconditions

`whoami` must return a Solo `process_id`. If not, stop and say so.

## 1. Identify the body of work

Work out the slug (git branch or worktree directory name, per the Solo session
hook). If this session *is* the work, that's it. If Jason invoked the skill
somewhere neutral, read the `Suspended Work` manifest (tag `manifest`) and ask
which body of work he means.

If a body of work can't be pinned down, ask — don't sweep. Repo-wide and
machine-wide sweeps are what `/clean-up-worktrees` and `/clean-up-sandboxes`
are for, and both are user-invoked; point Jason at them rather than doing it
here.

## 2. Build the inventory — read only

Nothing in this section changes anything.

**Agents and processes.** `list_processes`, then attribute as `/suspend` does:
agents you spawned this session, agents whose name starts with the slug, or
the `Agents` section of the start-here scratchpad. Check `get_process_status`
for each — flag any that are still busy. Never include an agent you can't
attribute; list it separately as unattributed.

**Git.**

```bash
git -C "$REPO" rev-parse --abbrev-ref HEAD
git -C "$REPO" worktree list
git -C "$REPO" status --short
git -C "$REPO" log --oneline origin/<default-branch>..<branch>
gh pr view <branch-or-number> --json number,state,url
```

Note: PR state, unpushed or unmerged commits, uncommitted changes.

**Sandbox.** Whether a Herd sandbox is backed by this worktree:

```bash
ls -d ~/Sites/Sandboxes/statamic-* 2>/dev/null
grep -l "$WORKTREE_PATH" ~/Sites/Sandboxes/statamic-*/composer.json 2>/dev/null
```

**Scratchpads.** `scratchpad_list` with `tags: ["<slug>"]`, plus the
start-here scratchpad and manifest row if they exist.

## 3. Present the inventory

Show what was found, grouped, with the state that matters — which agents are
idle vs busy, whether the PR is merged, whether anything is uncommitted or
unmerged, how many scratchpads. Call out anything unattributed or unclear.

## 4. Confirm each group

Ask with the multiple-choice picker, multi-select, one option per group that
actually has something in it:

- Close N agents and their processes
- Tear down sandbox `statamic-<branch>`
- Remove worktree `<path>` and delete branch `<branch>`
- Archive N scratchpads tagged `<slug>`
- Archive the start-here scratchpad and drop its manifest row

Only act on ticked groups. If Jason ticks nothing, stop — no fallback,
no "well, this one's obviously safe".

**The git gate.** Before offering worktree/branch removal, verify the work is
actually finished: PR merged or closed, nothing uncommitted, nothing unmerged.
If any of that fails, show him exactly what would be lost — the uncommitted
files, the unmerged commits — and require an explicit override before
offering it. Never quietly force.

If an agent is still busy, say so and leave it out of the default selection.
Closing a working agent loses the work.

## 5. Tear down, in this order

Order matters — later steps depend on earlier ones being gone.

1. **Agents and processes.** `close_process` each. Never pass
   `confirm_self_close`; this session stays up to report.

2. **Sandbox.** Delegate to the `statamic-sandbox` skill's teardown flow
   (section 7) — it stops the asset watcher, removes the parked site, and
   removes the worktree and branch. When there's a sandbox, that flow covers
   step 3 too; don't do it twice.

3. **Worktree and branch** (only when there was no sandbox):
   ```bash
   pkill -f '<absolute worktree path>'
   git -C "$REPO" worktree remove "<path>"
   git -C "$REPO" branch -d "<branch>"
   ```
   `pkill` scoped to the worktree path, so watchers from other work survive.
   Use `-d`; if it refuses, that's unmerged work — go back to Jason rather
   than reaching for `-D`.

4. **Scratchpads.** `scratchpad_archive` each one tagged with the slug.
   Archive, never `scratchpad_delete` — archiving hides them from lists
   without losing them.

5. **Start-here scratchpad and manifest row.** Archive the scratchpad, then
   `scratchpad_read` the manifest for its revision and `scratchpad_edit` the
   row out of the table.

## 6. Report

What was closed, removed and archived; what was deliberately left alone and
why; anything Jason still needs to deal with himself (an open PR, unpushed
commits, an unattributed agent).
