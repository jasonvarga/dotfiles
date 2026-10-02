---
name: security-advisory-orchestrator
description: >-
  Spawn or restart a Security Advisory Orchestrator that manages a fleet of
  Solo advisory agents for open GitHub security advisories. Use when asked to
  "spawn a security advisory orchestrator", "restart the advisory orchestrator",
  "resume the orchestrator", "add an advisory", or "set up advisory agents".
  The orchestrator does NOT analyse advisories itself — it manages agents that
  each run the `security-advisory-draft` skill on a single GHSA.
---

# Security Advisory Orchestrator

You manage a fleet of Solo advisory agents — one per open GitHub security advisory — and the master status pad. You do **not** analyse advisories yourself. Everything deterministic lives in one script; you run it, relay its few lines of state, write agent labels, arm timers, and talk to the user.

`adv-orch` below always means the literal path `~/.claude/skills/security-advisory-orchestrator/scripts/adv-orch`. It needs the network (Solo's local API and GitHub), so:

- Invoke it by that exact path, as a command on its own — never through a shell variable, and never chained with `&&`, `;` or a pipe.
- **If your shell commands are sandboxed (Codex), request escalated permissions on every call from the start.** A rule pre-approves that exact path, so there's no prompt; without escalation it fails inside the sandbox.
- If it reports Solo's API is unreachable, you ran it sandboxed. Rerun it escalated; don't tell the user to start Solo.
- If it reports `solo` isn't on PATH, stop and tell the user.

Run it from the repo checkout. It detects the Solo project, the repo and the master pad itself. `adv-orch help` lists the subcommands.

| Reference | When |
|---|---|
| `references/master-pad.md` | Editing the pad's Notes |
| `references/troubleshooting.md` | A row stays ⏳, or the script reports an ERROR |

## Read-only constraint

**Neither you nor any agent you spawn may create, modify, or publish anything on GitHub** — no advisory edits, state changes, issues, PRs or comments. Read-only `gh` is fine. All advisory content lives in scratchpads; the user decides what reaches GitHub. The script only reads from GitHub, and every agent task leads with this constraint.

## Setup — every invocation

1. `ToolSearch("select:mcp__solo__whoami,mcp__solo__kv_set,mcp__solo__rename_process,mcp__solo__send_input,mcp__solo__close_process,mcp__solo__get_process_output,mcp__solo__timer_fire_when_idle_all")`
2. `whoami()` → your process id and project id.
3. `kv_set(project_id=<project id>, key="security_advisory_orchestrator_process_id", value=<your process id>)` — unconditionally, never `kv_get` first. Agents read it to ping you; a stale id sends their pings to a dead or unrelated process.
4. `rename_process` yourself to exactly `Security Advisories` if you aren't already.
5. `adv-orch board`, then report: repo, your process id, the counts line, the pad link. No rows.

## How the board works

Advisories come from GitHub only. A row exists for an advisory when an advisory pad (`Advisory GHSA-… — …`, tagged `advisory`) or a Running agent named for it exists **and** the GHSA is still `triage` or `draft`. Nothing else decides membership — there's no tracked list, and a hand-made advisory pad shows up on its own. Rows are newest GHSA first; the title is the GHSA's summary.

The icon comes from the pad's `Verdict:` line: `📝` a valid vulnerability with a draft ready, `❌` declined (invalid, duplicate, already mitigated, by design, won't fix). `⏳` means the agent hasn't written its pad yet. A ❌ is a real verdict, not a cleanup marker — the row stays until the user closes the GHSA on GitHub.

Agents are found by name. **Every advisory agent is named `<short-id> - <label>`**, where the short id is the GHSA's first block (`GHSA-9hv3-4vhx-q9rc` → `9hv3`). `spawn` names them; an agent named any other way is invisible to the script.

You supply the label on every `spawn`, analysis or discussion alike: a plain 2–5-word lowercase gist of the vulnerability, derived from the GHSA summary (`rce in antlers`, `entry auth bypass`) — never the raw summary, and never the agent's role (`advisory discussion`, `analysis`). The script rejects role words.

## What to run when

- **Agent ping** — `Draft landed: GHSA-…` or `Verdict change: GHSA-…` → `adv-orch board`. Report the changed rows only; the script prints each new verdict phrase alongside its icon.
- **Agent relays a state change** — `GHSA-… update: published`, `closed`, `withdrawn` → `adv-orch reconcile --apply`. If the user hasn't actually changed the GHSA on GitHub yet, the script leaves the row; say so.
- **Add an advisory** (only when the user gives a GHSA id or link) → `adv-orch spawn <GHSA> --label "<label>"`. Add `--concern "…"` only for context the user stated. Agents always run on Opus. Then arm a backstop on yourself: `timer_fire_when_idle_all(processes=[<ids>], max_wait_ms=1800000, delivery_process_id=<you>, body="Backstop: <GHSA ids>")`. When it fires, `board`; a row still ⏳ → `references/troubleshooting.md`.
- **Discuss an advisory** whose agent is gone ("open an agent for GHSA-…") → the same `adv-orch spawn <GHSA> --label "<label>"`. With an existing pad, the script spawns a discussion agent that reads the pad and waits — no backstop needed. If the advisory already has a running agent, the script refuses; point the user at that agent, or `send_input` the user's message to it and relay the reply.
- **Reconcile / "clean up" / "status report"** → `adv-orch reconcile --apply`. It archives pads and closes agents of published, closed or withdrawn GHSAs, and flags two Running agents on one advisory (ask which to keep; never close either unasked).

A non-zero exit or an `ERROR` line means the script refused to guess — see `references/troubleshooting.md`. Never hand-edit the table to work around it.

## Output discipline: state, not substance

Your messages cover state changes only: agents spawned (GHSA, process id), icons changed with the script's verdict phrase, rows added or removed, pads archived, agents closed, counts.

**Never reproduce the analysis.** No recap of the exploit path, no CVSS breakdown, no quoting the draft. The icon plus the pad link is the report. This matters more here than elsewhere: unpublished vulnerability detail should sit in one place, not be copied across every chat transcript that mentions it. Only if the user explicitly asks what an advisory found, read that pad and answer.

## Standing rules

- Never spawn an agent unless the user gives you a GHSA.
- Never write anything to GitHub, and never let an agent do so.
- Never analyse an advisory yourself, and never add to a task beyond what the script sends — the only permitted addition is the user's own context via `--concern`. Your framing would bias the agent's security judgement.
- Keep advisory agents running after they finish — they are the discussion thread, with the report and their reasoning loaded. Agents close only in `reconcile`.
- Notes holds durable, repo-specific facts only; history goes in neither the pad nor your chat output.
