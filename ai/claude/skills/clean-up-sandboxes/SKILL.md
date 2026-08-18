---
name: clean-up-sandboxes
description: >-
  Scan ~/Sites/Sandboxes for Herd sandbox sites created by the statamic-sandbox
  skill's spinup-statamic helper, and work out which ones are orphaned (their
  worktree is gone, their branch is gone, or their PR is merged/closed) and
  safe to delete. Use when the user asks to clean up sandboxes, find orphaned
  sandboxes, or free up disk space from old PR sandboxes that were never torn
  down.
disable-model-invocation: true
---

# Clean Up Sandboxes

This skill is **user-invoked only** (`disable-model-invocation: true`) — it is
a machine-wide sweep, so it runs when Jason types `/clean-up-sandboxes`, never
on Claude's own initiative. Tearing down a single sandbox you spun up yourself
doesn't need this skill; use the `statamic-sandbox` teardown flow.

`spinup-statamic` sandboxes sometimes get abandoned without running the
`statamic-sandbox` teardown flow, leaving stale directories in
`~/Sites/Sandboxes`. This skill audits them and proposes which are safe to
remove.

## 1. Discover sandboxes

Only `statamic-*` subdirectories are in scope — those are the ones
`spinup-statamic` creates. `~/Sites/Sandboxes` is a shared Herd sites
directory, so other unrelated sites can end up in there too; never analyze
or suggest deleting anything that doesn't match this prefix.

```bash
ls -d ~/Sites/Sandboxes/*/ 2>/dev/null
```

Split the results: directories starting with `statamic-` go through the
analysis below. Note any others separately so they can be called out in the
summary (see step 3) — don't inspect their contents.

## 2. Analyze each sandbox

For each sandbox directory, work through this decision tree. Stop at the
first rule that matches and record its classification + reason.

### 2a. No composer.json

```bash
test -f "$site/composer.json"
```

If missing, classify **safe** — reason: "incomplete/failed spin-up (no
composer.json)". This covers sandboxes where `statamic new` never finished.

### 2b. Read the path repository

```bash
jq -r '.repositories[]? | select(.type=="path") | .url' "$site/composer.json"
```

If there's no such entry, classify **unclear** — reason: "composer.json has
no path repository, investigate manually". Otherwise call this `WORKTREE_PATH`.

Derive the main repo location:
- If `WORKTREE_PATH` contains `/.claude/worktrees/`, `CMS_REPO` is everything
  before that segment, and this sandbox is backed by a **worktree**.
- Otherwise `CMS_REPO` **is** `WORKTREE_PATH` — the sandbox was built directly
  against the main repo checkout, not a worktree.

### 2c. Worktree already gone

If this sandbox is backed by a worktree and `WORKTREE_PATH` no longer exists
on disk:

```bash
test -d "$WORKTREE_PATH"
```

Classify **safe** — reason: "worktree already removed". The sandbox's
symlinks are broken regardless of branch/PR state, so it's dead weight either
way.

### 2d. Determine the branch

- **Worktree case, still present:**
  ```bash
  git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD
  ```
  Also check if the worktree directory is named `pr-<n>` (the naming used by
  the statamic-pr skill). If so, prefer looking up the PR
  directly by number in step 2e — it's more reliable than the branch name,
  since `gh pr checkout` can leave a differently-named local branch in a
  dir called `pr-<n>`.
- **Main-repo case:** don't trust the repo's *current* branch — it may have
  moved on since this sandbox was built. Instead parse the branch out of the
  composer constraint that was recorded at spin-up time:
  ```bash
  jq -r '.require["statamic/cms"]' "$site/composer.json"
  ```
  This is either `dev-<branch> as <tag>` (extract `<branch>`) or a numeric
  release constraint like `6.x-dev` / `6.x-dev as <tag>`. For the latter,
  classify **unclear** — reason: "tracks a release branch, not a PR branch —
  check manually" (release-branch sandboxes don't get orphaned by branch
  deletion the same way).

### 2e. Check whether the branch/PR is still alive

Resolve the repo slug for `gh`:

```bash
git -C "$CMS_REPO" remote get-url origin
# → parse into owner/repo, e.g. statamic/cms
```

- If the worktree directory is named `pr-<n>`, look up by number:
  ```bash
  gh pr view <n> --repo <owner>/<repo> --json number,state,url
  ```
- Otherwise look up by branch:
  ```bash
  gh pr view "<branch>" --repo <owner>/<repo> --json number,state,url
  ```
  If that reports no PR found, also check whether the branch itself still
  exists, since a fork branch may not resolve via `gh pr view <branch>`:
  ```bash
  git -C "$CMS_REPO" show-ref --verify --quiet refs/heads/<branch>
  git -C "$CMS_REPO" ls-remote --exit-code --heads origin <branch>
  ```

Classify:
- PR found, state `MERGED` or `CLOSED` → **safe** — reason: "PR #n
  <state>".
- PR found, state `OPEN` → not orphaned, skip (still active work).
- No PR found, and the branch doesn't exist locally or on the remote either
  → **safe** — reason: "branch <branch> no longer exists".
- No PR found, but the branch still exists (or `gh` errored) → **unclear**
  — reason: "no PR found for <branch>, may be WIP — check manually".

## 3. Present the summary

Show a table of every sandbox that isn't active work, split into two groups:

- **Safe to remove** — name + reason.
- **Unclear** — name + reason, so the user can investigate.

Silently drop sandboxes classified as active (open PR / still in progress)
from the table, but mention the count.

If any non-`statamic-` directories were found in step 1, call them out
separately — name them and note they were skipped because they're outside
this skill's scope (not created by `spinup-statamic`).

## 4. Confirm before deleting

Ask the user to confirm before removing anything. List the safe sandboxes by
name. Only proceed on explicit confirmation — never delete the unclear ones
without the user directing you to.

## 5. Delete confirmed sandboxes

```bash
rm ~/Sites/Sandboxes/<name>
```

(`rm` is aliased to `trash`.) This only removes the sandbox site — it does
not touch the underlying worktree or branch. If any removed sandbox was
backed by a worktree that still exists, collect its `CMS_REPO` (from step
2b) and report it, rather than removing the worktree here.

`clean-up-worktrees` is user-invoked only, so you can't run it yourself —
tell the user to run `/clean-up-worktrees` if they want those swept, and
name the repos it should cover.
