---
name: statamic-pr-into-sandbox
description: >-
  Check out an existing statamic/cms PR into a worktree and run it in a Herd
  sandbox site. Use when the user says things like "spin up a sandbox for this
  PR", "get PR 1234 running locally", or otherwise wants to actually use a PR in
  a browser rather than just read it. Only operates inside the statamic/cms
  repo. Composes the statamic-pr and statamic-sandbox skills.
---

# Statamic PR Into Sandbox

End-to-end: take a `statamic/cms` PR, isolate it in a Claude-managed worktree,
and serve it from a Herd sandbox site with a live asset watcher.

Both setup phases run in a **single subagent**, so this session sees one summary
instead of several minutes of `gh`, `composer` and `statamic new` output. What
stays here: the guard, the worktree switch, the watcher, and the report.

## 1. Guard and identify the PR

```bash
git remote -v
```

If no remote points to `statamic/cms`, **stop** — this only works inside the
Statamic CMS repo. Then identify the PR number from context or `gh pr list`; if
it's ambiguous, ask rather than making the subagent guess.

## 2. Run both phases in one subagent

Call **Agent** with `subagent_type: general-purpose` and
`run_in_background: false`. Prompt:

> Do two things in order, for PR **&lt;n&gt;** in the repo at **&lt;absolute
> path to the main checkout&gt;**:
>
> 1. Follow the "Subagent brief" section of
>    `~/.claude/skills/statamic-pr/SKILL.md` to check the PR out into a
>    worktree.
> 2. If that succeeded, follow the "Subagent brief" section of
>    `~/.claude/skills/statamic-sandbox/SKILL.md` for the worktree you just
>    created, using the branch name you read in phase 1.
>
> If phase 1 fails, stop and report that — don't spin up a sandbox against a
> checkout that isn't ready. Report the combined fields from both briefs,
> including the worktree directory name chosen in phase 1
> (`pr-<n>-<description>`).

If the subagent reports a failure, surface its reason and stop. A failed phase 2
usually leaves a usable worktree — say so, so the user can retry the sandbox
alone with `statamic-sandbox`.

## 3. Enter the worktree

The subagent's session is gone; this one still needs to move. Call
**EnterWorktree** with the `path` the subagent reported (`.claude/worktrees/pr-<n>-<description>`)
— don't guess it, the description is chosen by the subagent.

## 4. Start the asset watchers

Started here, not in the subagent, so they survive past that session and stay
stoppable at teardown:

```bash
npm run dev            # run with run_in_background: true
npm run frontend-dev   # run with run_in_background: true
```

`npm run dev` rebuilds `resources/dist`, the CP bundle. `npm run frontend-dev`
rebuilds `resources/dist-frontend`, the front-end helpers bundle — `npm run dev`
does **not** touch it, they're separate Vite configs. `spinup-statamic`
symlinked both dirs into the sandbox, so edits to either show up live. Note
both background tasks so they can be stopped at teardown.

## 5. Report

Relay the subagent's summary — the agent's report isn't shown to the user. PR
number and title, branch, worktree path, sandbox URL, and that the watcher is
running in the background. Mention that `statamic-sandbox` handles teardown.
