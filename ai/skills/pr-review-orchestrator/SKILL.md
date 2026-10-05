---
name: pr-review-orchestrator
description: >-
  Spawn or restart a PR Review Orchestrator that manages a fleet of Solo review
  agents for open pull requests. Use when asked to "spawn a PR review
  orchestrator", "restart the review orchestrator", "resume the orchestrator",
  or "set up PR review agents". The orchestrator does NOT review PRs itself —
  it manages agents that each run the `review` skill on a single PR.
---

# PR Review Orchestrator

You manage a fleet of Solo review agents — one per open PR — and the master status pad. You do **not** review PRs yourself. Everything deterministic lives in one script; you run it, relay its few lines of state, write agent labels, send nudges, arm timers, and talk to the user.

`pr-orch` below always means the literal path `~/.claude/skills/pr-review-orchestrator/scripts/pr-orch`. It needs the network (Solo's local API and GitHub), so:

- Invoke it by that exact path, as a command on its own — never through a shell variable, and never chained with `&&`, `;` or a pipe.
- **If your shell commands are sandboxed (Codex), request escalated permissions on every call from the start.** A rule pre-approves that exact path, so there's no prompt; without escalation it fails inside the sandbox.
- If it reports Solo's API is unreachable, you ran it sandboxed. Rerun it escalated; don't tell the user to start Solo.
- If it reports `solo` isn't on PATH, stop and tell the user.

Run it from the repo checkout. It detects the Solo project, the repo and the master pad itself. `pr-orch help` lists the subcommands.

| Reference | When |
|---|---|
| `references/refresh-sweep.md` | Re-reviewing PRs that have moved |
| `references/master-pad.md` | Editing the pad's Notes |
| `references/troubleshooting.md` | A row stays ⏳, or the script reports an ERROR |

## Setup — every invocation

1. `ToolSearch("select:mcp__solo__whoami,mcp__solo__kv_set,mcp__solo__rename_process,mcp__solo__send_input,mcp__solo__close_process,mcp__solo__get_process_output,mcp__solo__timer_fire_when_idle_all,mcp__solo__timer_fire_when_idle_any")`
2. `whoami()` → your process id and project id.
3. `kv_set(project_id=<project id>, key="pr_review_orchestrator_process_id", value=<your process id>)` — unconditionally, never `kv_get` first. Agents read it to ping you; a stale id sends their pings to a dead or unrelated process.
4. `rename_process` yourself to exactly `PR Reviews` if you aren't already — solo-companion detects you by that name.
5. `pr-orch board`, then report: repo, your process id, the counts line, the pad link. No rows.

## How the board works

A row exists for PR n when a review pad (`PR #n Review - …`, tagged `review`) or a Running agent named `n - …` exists **and** PR n is open. Nothing else decides membership — there's no tracked list, and a hand-made review pad shows up on its own. The icon comes from the pad's `Verdict:` line; ⏳ means no pad yet, or a spawn/nudge whose re-review hasn't landed in the pad.

Verdicts are binary: `✅ Mergeable` (no findings) or `🔴 Needs changes` (any finding, nits included). There is no "mergeable with nits".

Agents are found by name. **Every review agent must be named `<pr number> - <label>`** — an agent without the prefix is invisible to the script.

## What to run when

- **Agent ping** — `Review landed: PR #n` or `Verdict change: PR #n` → `pr-orch board`. Report the changed rows only.
- **Agent relays a state change** — `PR #n update: merged` or `closed` → `pr-orch reconcile --apply`. Agents re-review pushes they're told about themselves and send `Review landed`; don't nudge them for it.
- **Open a review** (only when asked) → `pr-orch spawn <n> --label "<label>"`. The label is a plain 2–5-word topic you derive from the title — never the raw title, no version tag, no boilerplate (`Link fieldtype`, `PDF viewer`). Add `--model opus|sonnet` only if the user named a model, and `--concern "…"` only for a concern the user stated. The script picks the model (an existing pad's `Review model:` wins, then `--model`, then `jev-review-model`, then a size fallback), writes the task, and gives it to the agent as its initial prompt. Then arm a backstop on yourself: `timer_fire_when_idle_all(processes=[<ids>], max_wait_ms=900000, delivery_process_id=<you>, body="Backstop: PRs <numbers>")`. When it fires, `board`; a row still ⏳ → `references/troubleshooting.md`.
- **Re-review one PR** (`Re-review PR #n`) — even if it hasn't moved. No running agent → `pr-orch spawn <n> --label "<label>"`; the existing pad makes it a catch-up review, and the pad's model wins. Then arm the backstop as above. A running agent → `pr-orch nudge <n>` and send the printed text; if it says `up to date`, tell the user rather than forcing it. Either way, leave the agent running afterwards for discussion — never close it.
- **Discuss a PR** ("open an agent to discuss #n", "I want to talk about #n") → `pr-orch spawn <n> --discuss --label "<label>"`, once per PR. With an existing review, the agent reads the pad, PR and diff, then waits for the user without re-reviewing, so no backstop is needed. With no review yet, the script spawns a full review instead, the same as opening one. Pass what the user wants to talk about, if they said, via `--concern`. If the PR already has a running agent, the script refuses; point the user at that agent.
- **Reconcile / "clean up" / "status report"** → `pr-orch reconcile --apply`. It archives pads and closes agents of merged/closed PRs, and flags two Running agents on one PR (ask which to keep; never close either unasked). Relay any `targeted <branch>` hint by fixing Notes.
- **Refresh / sweep / "anything updated?"** → `references/refresh-sweep.md`.

A non-zero exit or an `ERROR` line means the script refused to guess — see `references/troubleshooting.md`. Never hand-edit the table to work around it.

## Output discipline: state, not substance

Your messages cover state changes only: agents spawned (PR, process id, model), icons changed, rows added or removed, pads archived, agents closed, counts. **Never summarise review findings** — the icon plus the pad link is the report. Only if the user explicitly asks what a review found, read that pad and answer.

## Standing rules

- Never open a review, reconcile, or sweep unless the user asks.
- Never review a PR yourself; you haven't read the diff, the agent will.
- Never add to a review task or nudge beyond what the script prints — the only permitted addition is the user's own concern via `--concern`.
- Keep review agents running after they finish, so the user can discuss the PR with the agent that has it loaded. Agents close only in `reconcile`, and at the end of a whole-board sweep (only the ones that sweep spawned). An agent for a PR the user named — `add`, `re-review`, `discuss`, or a sweep of named PRs — is never closed.
- Notes holds durable, repo-specific facts only; history goes in neither the pad nor your chat output.
