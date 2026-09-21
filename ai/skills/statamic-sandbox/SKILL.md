---
name: statamic-sandbox
description: >-
  Spin up (or tear down) a Herd sandbox site backed by the current statamic/cms
  branch, using the spinup-statamic shell function, plus asset watchers. Use
  when the user wants a sandbox for a branch or worktree they already have, or
  wants to start a new statamic/cms branch in a sandbox, or says "tear down the
  sandbox" / "clean up this sandbox". Only operates inside the statamic/cms
  repo. To check a PR out first, use statamic-pr-into-sandbox.
---

# Statamic Sandbox

Create a Herd sandbox site at `<name>.test` that runs against a checkout, via
the `spinup-statamic` shell function, and keep asset watchers running so edits
show up live. Also tears the sandbox down when done.

`spinup-statamic` runs `statamic new` plus a full `composer update`, so the
spinup runs in a **subagent** to keep minutes of build output out of this
session. The asset watchers are deliberately started *here* instead — a
background task dies with the subagent that started it, and this one needs to
survive across turns and still be stoppable at teardown.

## 1. Guard: must be in statamic/cms

```bash
git remote -v
```

If no remote points to `statamic/cms`, **stop** and tell the user this skill
only works inside the Statamic CMS repo. Do not proceed.

## 2. Determine intent: spinup or teardown

Read the conversation context; confirm only if genuinely unsure.

- "spin up a sandbox", "give me a site for this" → [Spinup](#3-spinup).
- "clean up", "done with this", "tear down the sandbox" → [Teardown](#7-teardown).

## 3. Spinup: make sure there's a branch to back it

Cheap and decision-heavy, so do this here rather than in the subagent.
`spinup-statamic` bails on a detached HEAD, and a sandbox pinned to the main
checkout's branch goes stale as soon as that checkout moves on, so a worktree is
strongly preferred.

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse --show-toplevel
```

- **Already in a worktree on a named branch** → continue to step 4.
- **A PR is in play but not checked out yet** → use `statamic-pr-into-sandbox`
  instead; it does both phases in a single subagent.
- **The user is starting new work** → derive a branch name from the task (e.g.
  `fix-asset-upload`, `feature/glide-presets`), **confirm it with the user**,
  then create the worktree + branch by calling **EnterWorktree** with
  `name: <branch>`. In `fresh` mode (the default) this branches from
  `origin/<default branch>` and switches this session into
  `.claude/worktrees/<branch>`.
- **In the main checkout on the default branch with no clear intent** → ask
  before building a sandbox against it.

## 4. Delegate the spinup to a subagent

Call **Agent** with `subagent_type: general-purpose` and
`run_in_background: false`. Prompt:

> Follow the "Subagent brief" section of
> `~/.claude/skills/statamic-sandbox/SKILL.md` for the checkout at
> **&lt;absolute worktree path&gt;** on branch **&lt;branch&gt;**. Report back
> exactly as that brief specifies.

If it reports a failure, surface the reason and stop. In particular, "site
already exists" means an old sandbox is still parked — offer teardown or a
different name rather than retrying.

## 5. Start the asset watchers

Always start both (no "build or watch?" prompt), from this session, **in the
background**:

```bash
npm run dev            # run with run_in_background: true
npm run frontend-dev   # run with run_in_background: true
```

`npm run dev` (plain `vite`) watches `resources/js` and rebuilds
`resources/dist`, the CP bundle. `npm run frontend-dev` uses the separate
`vite-frontend.config.js` and rebuilds `resources/dist-frontend`, the
front-end helpers bundle — `npm run dev` does **not** touch it. `spinup-statamic`
symlinked both dirs into the sandbox, so edits to either show up live at
`<name>.test`. Both watchers stay up while you work; they only re-surface if
one exits. Note both background tasks so they can be stopped at teardown.

If this session isn't in the worktree (e.g. the spinup was for a path elsewhere),
add `--prefix <worktree>` to each command instead.

## 6. Report

Relay the subagent's summary — the agent's report isn't shown to the user. The
site URL (`http://<name>.test`), the branch, and that the watchers are running.

## 7. Teardown

Small and interactive, so it stays in this session. Removing the parked site
directory is enough for Herd; also remove the worktree. Teardown usually runs in
a **different session** than spinup, so don't assume the name is in context —
discover it.

1. **Discover candidates.** List the worktrees and sandbox sites this skill
   creates:
   ```bash
   git worktree list
   ls -d ~/Sites/Sandboxes/statamic-* 2>/dev/null
   ```
   The sandbox `statamic-<branch>` pairs with the worktree whose branch
   sanitizes to `<branch>`.

2. **Pick the target.**
   - If the conversation clearly names which sandbox/branch → use it.
   - If exactly one candidate exists → use it, but state which one before
     removing.
   - If multiple (or the pairing is ambiguous) → ask the user which to tear
     down. Never guess when more than one exists.

   If the user is asking about stale sandboxes in general rather than a specific
   one, that's a job for `clean-up-sandboxes` — which is user-invoked only, so
   tell them to run `/clean-up-sandboxes` rather than sweeping yourself.

3. **Stop the asset watchers.** They hold the worktree dir open, so kill them
   before removing anything.
   - If this session started them, stop those background tasks (both
     `npm run dev` and `npm run frontend-dev`).
   - Otherwise find and kill the vite processes for this worktree, e.g.
     `pkill -f '<absolute worktree path>'` (scope it to the worktree path so
     you don't kill a watcher from another sandbox).

4. **Remove the sandbox site** (`rm` is aliased to `trash`):
   ```bash
   rm ~/Sites/Sandboxes/statamic-<sanitized-branch>
   ```

5. **Remove the worktree:**
   - If this session created it via EnterWorktree, call **ExitWorktree** with
     `action: remove` (use `discard_changes: true` only after confirming with
     the user if it warns about unmerged/uncommitted changes).
   - Otherwise:
     ```bash
     git worktree remove .claude/worktrees/<name>
     ```
     If it refuses due to uncommitted changes, surface that and confirm before
     forcing. Offer to delete the local branch if it's no longer needed.

6. Confirm what was removed.

---

## Subagent brief: spin up the sandbox site

Everything below is for the subagent. Work by absolute path — **do not call
EnterWorktree or ExitWorktree**, and **do not start `npm run dev` or
`npm run frontend-dev`**; the parent session owns the watchers so they outlive
you.

1. Make sure the checkout's dependencies are installed (`statamic-pr` may have
   done this already):
   ```bash
   test -d <worktree>/vendor || composer install -d <worktree>
   test -d <worktree>/node_modules || npm ci --prefix <worktree>
   ```
2. Work out the sandbox name: `statamic-<branch>`, with the branch sanitized for
   a hostname (lowercase; `/` and any non-alphanumeric → `-`). It will be served
   at `<name>.test`.
3. Spin it up, passing the checkout as the package path:
   ```bash
   spinup-statamic statamic-<sanitized-branch> <worktree>
   ```
   - `spinup-statamic` is a zsh function from the user's profile. If it's not
     found, invoke via `zsh -ic 'spinup-statamic ...'`.
   - It runs `statamic new` + a full `composer update`, so it can take a few
     minutes. Use a long timeout, or run in the background and poll.
   - It bails if `~/Sites/Sandboxes/<name>` already exists, or on a detached
     HEAD — report either error rather than retrying blindly.

Report back, and nothing else:

- **Status** — succeeded, or which step failed and why (include the relevant
  error lines, not the full output).
- **URL** — the `http://<name>.test` it printed.
- **Sandbox path** — `~/Sites/Sandboxes/<name>`.
- **Worktree** — absolute path, and the branch it's on.
- **Deps** — whether anything needed installing in step 1.
