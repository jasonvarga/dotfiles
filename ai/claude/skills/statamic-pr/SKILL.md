---
name: statamic-pr
description: >-
  Check out an existing statamic/cms PR into a Claude-managed git worktree and
  install its dependencies. Use when the user says things like "check this PR
  out", "check this PR out into a worktree", "get PR 1234 locally", or
  otherwise wants a PR branch isolated in its own working directory. Only
  operates inside the statamic/cms repo. Does NOT create a sandbox site — use
  statamic-pr-into-sandbox for that.
---

# Statamic PR Worktree

Check out a `statamic/cms` PR into a Claude-managed git worktree under
`.claude/worktrees/`, so it can be read, run and tested without disturbing the
main checkout.

The setup itself runs in a **subagent** — `gh`, `composer install` and `npm ci`
produce a lot of output that's worthless once they've succeeded. This session
only handles the guard, the worktree switch, and the summary.

This skill stops once the worktree is ready. If the user also wants a running
site, that's `statamic-pr-into-sandbox` (which runs both phases in one subagent).

## 1. Guard: must be in statamic/cms

Do this here, not in the subagent, so a wrong repo fails immediately:

```bash
git remote -v
```

If no remote points to `statamic/cms` (e.g. `git@github.com:statamic/cms.git` or
a fork whose upstream is `statamic/cms`), **stop** and tell the user this skill
only works inside the Statamic CMS repo. Do not proceed.

## 2. Identify the PR

From context, or `gh pr list`. If it's ambiguous, ask — don't make the subagent
guess.

## 3. Delegate the setup to a subagent

Call **Agent** with `subagent_type: general-purpose` and
`run_in_background: false` (the result is needed before continuing). Prompt:

> Follow the "Subagent brief" section of
> `~/.claude/skills/statamic-pr/SKILL.md` for PR **&lt;n&gt;** in the repo at
> **&lt;absolute path to the main checkout&gt;**. Report back exactly as that
> brief specifies.

If the subagent reports a failure, surface its reason to the user and stop —
don't retry blindly or paper over a half-created worktree.

## 4. Enter the worktree

The subagent's session is gone; this one still needs to move. Call
**EnterWorktree** with `path: .claude/worktrees/pr-<n>`.

## 5. Report

Relay the subagent's summary — the agent's report isn't shown to the user. PR
number and title, branch, worktree path. Mention that `statamic-sandbox` can
spin up a Herd site from here if they want to actually run it.

---

## Subagent brief: check out a PR into a worktree

Everything below is for the subagent. Work by absolute path — **do not call
EnterWorktree or ExitWorktree**, and do not start an asset watcher; the parent
session handles both.

1. Get the default branch and make sure it's current:
   ```bash
   DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)   # e.g. 6.x
   git -C <repo> fetch origin "$DEFAULT"
   ```
2. Create a detached worktree from the default branch:
   ```bash
   git -C <repo> worktree add --detach .claude/worktrees/pr-<n> "origin/$DEFAULT"
   ```
   Keep the `pr-<n>` directory name — the `clean-up-sandboxes` and
   `clean-up-worktrees` skills use it to look the PR up later.
3. Check the PR out from inside the worktree. `gh` has no `-C`, so cd for this
   one; it handles fork remotes correctly, which a manual fetch wouldn't:
   ```bash
   cd <repo>/.claude/worktrees/pr-<n> && gh pr checkout <n>
   ```
   This fetches the PR head, sets up the branch (and fork remote if needed), and
   switches to it — no longer detached.
4. Read the resulting branch name — `gh pr checkout` may not name it after the
   directory:
   ```bash
   git -C <worktree> rev-parse --abbrev-ref HEAD
   ```
5. Install dependencies. A worktree is a separate working dir and `vendor/` /
   `node_modules/` aren't in git, so nothing works until these finish:
   ```bash
   composer install -d <worktree>
   npm ci --prefix <worktree>
   ```
   These take a while — use a long timeout. If either fails, don't remove the
   worktree; report the failure and let the user decide.

Report back, and nothing else:

- **Status** — succeeded, or which step failed and why (include the relevant
  error lines, not the full output).
- **PR** — number and title.
- **Branch** — the name from step 4.
- **Worktree** — absolute path.
- **Deps** — whether `composer install` and `npm ci` both succeeded.
