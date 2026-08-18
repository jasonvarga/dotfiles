---
name: clean-up-worktrees
description: >-
  Scan a repo's `.claude/worktrees/` directory and work out which worktrees
  are orphaned (their branch was deleted, or their associated PR is
  merged/closed) and safe to remove. Use when the user asks to clean up
  worktrees, find orphaned worktrees, or free up disk space from old PR
  worktrees that were never torn down.
disable-model-invocation: true
---

# Clean Up Worktrees

This skill is **user-invoked only** (`disable-model-invocation: true`) — it is
a repo-wide sweep, so it runs when Jason types `/clean-up-worktrees`, never on
Claude's own initiative. Tearing down a single worktree you created yourself
doesn't need this skill; just remove that one worktree directly.

Claude-managed worktrees (created via `EnterWorktree` or `git worktree add
.claude/worktrees/<name>`) sometimes get left behind after their PR is done
with, wasting disk space and leaving stale checkouts around. This skill
audits a repo's worktrees and proposes which are safe to remove.

## 0. Determine repo scope

- If invoked with specific repo path(s) already in context (e.g. the user
  ran this after `clean-up-sandboxes` named particular `CMS_REPO` values),
  use those.
- Otherwise use the repo containing the current working directory.
- If neither is clear, ask the user which repo to check.

Confirm `.claude/worktrees/` exists in that repo; if not, report there's
nothing to clean up and stop.

## 1. Discover worktrees

```bash
git -C "$REPO" worktree list --porcelain
```

Filter to entries whose path is under `$REPO/.claude/worktrees/`. Ignore the
main worktree and anything outside that directory (this skill only manages
Claude-created worktrees, not arbitrary ones).

For each match, note its path and current branch.

## 2. Analyze each worktree

### 2a. Look up the PR

Resolve the repo slug once:

```bash
git -C "$REPO" remote get-url origin
# → parse into owner/repo
```

- If the worktree directory is named `pr-<n>` (the naming used by the
  statamic-pr skill), look up by number — more
  reliable than the branch name, since `gh pr checkout` can leave a
  differently-named local branch in a dir called `pr-<n>`:
  ```bash
  gh pr view <n> --repo <owner>/<repo> --json number,state,url
  ```
- Otherwise look up by branch:
  ```bash
  gh pr view "<branch>" --repo <owner>/<repo> --json number,state,url
  ```
  If that reports no PR found (common for fork branches), also check
  whether the branch still exists locally or remotely:
  ```bash
  git -C "$REPO" show-ref --verify --quiet refs/heads/<branch>
  git -C "$REPO" ls-remote --exit-code --heads origin <branch>
  ```

### 2b. Classify

- PR found, state `MERGED` or `CLOSED` → **safe** — reason: "PR #n
  <state>".
- PR found, state `OPEN` → active, skip (still in progress).
- No PR found, branch doesn't exist locally or remotely either → **safe**
  — reason: "branch <branch> deleted, no PR found".
- No PR found, branch still exists (or `gh` errored) → **unclear** —
  reason: "no PR found for <branch>, may be WIP — check manually".

### 2c. Check for dependent sandboxes

A worktree may still be backing a live Herd sandbox created by
`spinup-statamic`. Check whether any sandbox references this worktree path:

```bash
grep -l "$WORKTREE_PATH" ~/Sites/Sandboxes/statamic-*/composer.json 2>/dev/null
```

If one does, note it in the summary (e.g. "still used by sandbox
`statamic-foo`") regardless of classification — removing the worktree will
break that sandbox's symlinks. This is informational; it doesn't change the
safe/unclear classification, which stays purely branch/PR based.

## 3. Present the summary

Table of every worktree that isn't active work, split into:

- **Safe to remove** — path/branch + reason + any dependent sandbox note.
- **Unclear** — path/branch + reason.

Silently drop active worktrees from the table, but mention the count.

## 4. Confirm before removing

Ask the user to confirm before removing anything. List the safe worktrees.
Only proceed on explicit confirmation — never remove the unclear ones
without the user directing you to. If a worktree has a dependent sandbox,
call it out again here so the user can decide to remove the sandbox too
(via `clean-up-sandboxes` or manually) — don't remove sandboxes yourself
from this skill.

## 5. Remove confirmed worktrees

For each:

1. Stop anything holding the worktree dir open (e.g. an `npm run dev` /
   vite watcher started by `statamic-sandbox`):
   ```bash
   pkill -f '<absolute worktree path>'
   ```
2. Remove the worktree:
   ```bash
   git -C "$REPO" worktree remove "<path>"
   ```
   If it refuses due to uncommitted changes, surface that and confirm with
   the user before adding `--force`.
3. Offer to delete the local branch too:
   ```bash
   git -C "$REPO" branch -d "<branch>"
   ```
   Use `-d` (safe delete) when the PR was merged. If the PR was closed
   without merging, `-d` will refuse — confirm with the user before using
   `-D`.

## 6. Confirm what was removed
