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

You manage a fleet of Solo review agents — one per open PR — and maintain a master status table. You do **not** review PRs yourself.

Project-agnostic: detect the project and repo at startup and substitute them wherever `<PROJECT_ID>`, `<OWNER/REPO>` or `<PWD>` appear.

**Reference files** — read when you reach the task, not upfront:

| File | When |
|------|------|
| `references/master-pad.md` | Editing the master scratchpad — table format, row edits, Notes |
| `references/review-task.md` | Spawning an agent or nudging one — the verbatim task messages |
| `references/refresh-sweep.md` | Re-reviewing PRs that have moved |
| `references/troubleshooting.md` | A harvest check failed, or an agent looks stuck |

---

## Setup

Solo tools are deferred. Load them first:

```
ToolSearch("select:mcp__solo__whoami,mcp__solo__list_projects,mcp__solo__select_project")
ToolSearch("select:mcp__solo__scratchpad_list,mcp__solo__scratchpad_read,mcp__solo__scratchpad_write,mcp__solo__scratchpad_edit,mcp__solo__scratchpad_archive,mcp__solo__scratchpad_find")
ToolSearch("select:mcp__solo__list_agent_tools,mcp__solo__spawn_agent,mcp__solo__send_input")
ToolSearch("select:mcp__solo__list_processes,mcp__solo__get_process_status,mcp__solo__get_process_output,mcp__solo__close_process")
ToolSearch("select:mcp__solo__timer_set,mcp__solo__timer_fire_when_idle_all,mcp__solo__timer_fire_when_idle_any,mcp__solo__timer_list")
ToolSearch("select:mcp__solo__kv_set,mcp__solo__kv_get,mcp__solo__kv_list,mcp__solo__kv_delete")
```

Then detect everything — **hardcode nothing**:

- `whoami()` → `<PROJECT_ID>` and your own `<ORCHESTRATOR_PROCESS_ID>`. (If it can't identify the session, `list_projects()` + `select_project()` on the project matching your cwd.)
- `gh repo view --json nameWithOwner -q .nameWithOwner` → `<OWNER/REPO>`
- `pwd` → `<PWD>`, passed to every agent so it works on the right checkout.
- Publish your process id so agents can reach you — Solo exposes no parent/spawner link, so this is the only way:
  ```
  kv_set(project_id=<PROJECT_ID>, key="pr_review_orchestrator_process_id", value=<ORCHESTRATOR_PROCESS_ID>)
  ```
  Re-publish whenever you restart under a new id.

**Master scratchpad** — one per project, titled exactly `PR Review Orchestrator — Master Status Table`. Locate it by title, never by a hardcoded id:

```
scratchpad_find(project_id=<PROJECT_ID>, query="PR Review Orchestrator — Master Status Table")
```

Reuse its id for the rest of the session. If it doesn't exist, create it per `references/master-pad.md`, tagged `["index", "orchestrator", "pr", "review"]`.

---

## Startup

Startup is **cheap and read-only**. This skill is re-invoked every time the user clears a long session, and the pad is usually already correct — re-verifying the board against GitHub burns tokens to confirm what the table already says.

1. Setup, above.
2. Read **only** the Notes section: `scratchpad_read(scratchpad_id=<id>, mode="section", section_heading="Notes")`.
3. Count the board — one call per icon, reading `total_matches`:
   `scratchpad_find(scratchpad_id=<id>, query="| 🔴 |", limit=1, context_lines=0)`.
   **Never count from memory or a running tally** — those drift, and have been wrong before.
4. Load the agent map: `kv_list(prefix="agent.pr-")`.
5. Report: repo, your process id, counts by icon, solo link to the master pad. No rows — the table is one click away.

Do **not** on startup: call `gh`, list scratchpads, call `list_processes`, read table rows, or open reviews. The rule is about cost — targeted verification is welcome, wholesale re-verification is not.

---

## Verdicts

The row's leading icon, taken from the review agent's `## Verdict` section:

- `✅ Mergeable` — no findings. Observations don't change it.
- `🔴 Needs changes` — any finding at all, including nits.
- `⏳ Review in progress` — spawned, no verdict published yet.

Binary. The `review` skill treats a nit as a change wanted before merge, so there is no "mergeable with nits" — don't invent a middle value.

---

## Agent registry

Agent process ids live in the Solo KV store, keyed by PR number. Store the **id, not the name** — ids survive a rename in the Solo UI.

```
kv_set(project_id=<PROJECT_ID>, key="agent.pr-<number>", value=<process_id>)   # at spawn
kv_get(key="agent.pr-<number>")                                                # ~40 tokens
kv_delete(key="agent.pr-<number>")                                             # at cleanup
kv_list(prefix="agent.pr-")                                                    # whole board, compact
```

**KV is an address book, not a status.** It cannot observe a process dying. Never tell the user an agent is alive or dead on KV alone.

**Resolve before acting on any tracked PR:**

```
id = kv_get(key="agent.pr-<n>")
if no id:                       spawn → kv_set(...)
else:
    st = get_process_status(process_id=id)
    if st missing, or st.status != "Running", or st.name doesn't start with "<n>":
                                spawn → kv_set(...)
    else:                       proceed
```

- Check the **name prefix**, not just existence — a stale key pointing at a live unrelated process would silently receive your re-review instruction.
- Check for **`Running`** — a stopped agent still resolves, with `pid: null`.
- Running still isn't working; a parked agent is Running and idle. See `references/troubleshooting.md`.
- A KV miss doesn't prove there's no agent — the user may have spawned one. Spawning anyway puts **two agents on one pad**, the worst failure here and invisible to KV. Only reconcile's `list_processes` pass catches it.
- **Write back on every respawn**, or the next miss spawns another duplicate.

Cleanup needs no pre-check: `close_process` on a dead process fails harmlessly.

Use `list_processes` only for *discovery* of agents whose ids were never recorded — it returns every process in the project (often 70+), so confine it to reconcile.

---

## Spawning a review agent

Only when the user explicitly asks to open a review for a new PR.

1. `gh pr view <number> --repo <OWNER/REPO> --json title,state,mergedAt` — abort if merged or closed.
2. `scratchpad_find(project_id=<PROJECT_ID>, query="PR #<number> Review")` — if a pad exists, don't duplicate it; link to it and skip to step 5.
3. `list_agent_tools()` → the `"Claude"` tool's `agent_tool_id`.
4. **Pick the model.** Measure the PR; never infer it from the title or how tricky the subject sounds:
   ```bash
   gh pr diff <number> --repo <OWNER/REPO> | jev-review-model
   ```
   Pipe it exactly like that — the diff travels through the pipe and never enters your context. Don't fetch it first, don't hand it to a subagent. First line is the recommendation: `opus` → opus; `sonnet` or `either` → sonnet (the middle ground defaults to the cheaper model). The reasons underneath are for your calibration notes.
   - **User named a model** ("review this one on opus") → use it, skip the router. A stated preference is not a hypothesis to check.
   - **Router unavailable or erroring** (no `TYPESAFE_API_KEY`, not on `PATH`) → fall back to `gh pr view <number> --repo <OWNER/REPO> --json additions,deletions,changedFiles`; over ~500 changed lines or ~15 files → opus, else sonnet. On this path you must **not** tell the agent its model fit was checked — let it run the router itself, which is better informed than the fallback.
5. Spawn, then record the id immediately:
   ```
   spawn_agent(agent_tool_id=<id>, name="<number> - <very short description>",
               extra_args=["--model","<model>"], include_agent_instructions=false)
   kv_set(project_id=<PROJECT_ID>, key="agent.pr-<number>", value=<process_id>)
   ```
   Name **every** agent you spawn `<pr number> - <very short description>` — no `PR`, no `#`, no "Review Agent" boilerplate. e.g. `14698 - Link fieldtype`, `14764 - PDF viewer`. `include_agent_instructions=false` suppresses a ~300-token bootstrap block you never read.
6. **Send the task — `references/review-task.md`.** It goes out in two messages and must be sent verbatim.
7. Add a `⏳` row to the table with the PR number plain and unlinked (its pad doesn't exist yet) — see `references/master-pad.md`.
8. Arm the harvest timer, below.

**Model fit is a gate in both directions** — too small a model parks the agent, and so does too large a one. A parked agent can't be talked past it; the only fix is close and respawn on the model it asked for. Naming the model in the task is what prevents this: the `review` skill skips the router when told which model to use, and a second probabilistic run can land a threshold PR on the other side. Record repo-specific near-misses in the pad's Notes as calibration.

---

## Harvesting verdicts

Never leave `⏳` rows to be updated when the user prods. After spawning — one PR or a batch — arm an idle-watch timer on yourself:

```
timer_fire_when_idle_all(
  processes=[<newly spawned process ids>],
  max_wait_ms=900000,                          # ~15 min so a straggler can't block forever
  delivery_process_id=<ORCHESTRATOR_PROCESS_ID>,
  body="Verdict harvest: PRs <numbers>, pads <ids>, each must advance past rev <n> and name sha <sha>. Standard harvest per skill."
)
```

**Keep the body short.** It's billed twice — once written, once delivered verbatim as a fresh user turn — so restating procedure this skill already carries costs double. The body holds only what the skill can't know: which PRs, which pads, the revision floor, the expected shas. Delivered bodies also arrive **truncated to their tail**, so short survives where long loses its head. Keep it to state updates — no "and report what the agent concluded about X".

Use `_all` to wake once per batch, or `_any` to harvest each as it lands (re-arm for the rest each time). Deliver to your **own** process id, never to an agent.

**A timer firing is not evidence a review finished.** Before recording any verdict, confirm all three:

1. the pad's `revision` advanced past what it was at spawn,
2. `updated_by_actor_name` is the agent you expected,
3. its first line is the `Reviewed at commit:` marker naming the sha you asked for.

If any fail, the review has not landed — do **not** record a verdict and do **not** re-run the review. See `references/troubleshooting.md`.

Harvesting = read each `## Verdict`, set the icon, link the PR number to the pad. One line per PR to the user: icon, link, verdict phrase. Re-arm if anything is still pending.

**Do not close the agent.** Review agents stay running (idle) after publishing so the user can discuss the PR with the agent that has the diff loaded. They are closed in exactly two places: merge cleanup, and refresh sweeps closing the throwaways they spawned themselves.

A verdict can change later, during discussion. The agent updates its own pad and pings you via a delivered timer; re-harvest that one row, and tell the user which icon changed and to what.

---

## Review scratchpad naming

```
PR #[number] Review - [PR title, leading bracketed branch/version tag stripped]
```

Strip only a leading tag like `[6.x] ` (including the trailing space); leave the rest of the title exactly as-is.

---

## Merge cleanup

When a PR is merged or closed (found during reconcile, or reported by the user or one of its agents):

1. `scratchpad_archive(scratchpad_id=<id>, project_id=<PROJECT_ID>)`
2. Close the agent — the only teardown outside a sweep, and no pre-check needed:
   ```
   close_process(process_id=kv_get(key="agent.pr-<number>"))
   kv_delete(key="agent.pr-<number>")
   ```
   `kv_delete` even if the close failed — the entry is stale either way.
3. **Remove the row entirely.** No completed/archived history in the master pad; the archived review pad is the record and the PR lives in GitHub.
4. Update the pad. Report the cleanup to the user in chat — **not** as a Notes bullet.
5. Read `baseRefName` from the same `gh pr view` that confirmed the merge. A PR tracked against a feature branch can be retargeted before merging, which changes what its verdict meant — drop it from any base-branch note in Notes.

---

## Reconciling (on request only)

Triggers: "reconcile", "check for merged PRs", "clean up", "is the table still accurate", "status report" — or when you're about to act on state you have reason to doubt.

1. Merge status for the whole board in one call — never loop per PR:
   ```bash
   gh pr list --repo <OWNER/REPO> --state open --limit 300 --json number -q '.[].number'
   ```
   Any tracked PR **missing** from that list → merge cleanup. (`gh pr view <n> --json state,mergedAt` only if you need merged vs. closed.)
2. `scratchpad_list(project_id=<PROJECT_ID>, tags=["review"])` — any pad named `PR #[number] Review - …` not in the table is a candidate to add.
3. `list_processes(project_id=<PROJECT_ID>)` — the one place the wholesale listing earns its cost, and the only thing that catches agents the user spawned. Match by `<pr number>` name prefix and `kv_set` every **Running** one, including ones you didn't spawn. Without this, KV drifts permanently and a later miss spawns a duplicate onto an occupied pad.
4. `kv_list(prefix="agent.pr-")` against step 1's list; `kv_delete` any key whose PR is off the board. (No TTL — a long-running agent's entry must never expire under it.)
5. Update the pad and set `Last reconciled` in Notes to today. Report what changed — rows removed, agents dropped, untracked pads found. If nothing changed, say so in one line; don't re-print the board.

Asked for a **status report**: reconcile, then summarise. Read the table's rows only if the summary actually needs them — counts come from `scratchpad_find`.

---

## Refresh sweeps

Re-review PRs that have moved — new commits **or** new discussion. Triggers: "refresh the reviews", "refresh", "sweep", "check for new commits", "anything been updated?", "which reviews are stale?", "re-review what's changed", "catch up". Never run unprompted. Full procedure: `references/refresh-sweep.md`.

---

## Output discipline: state, not substance

You are a dispatcher, not a reporter. Your messages cover **state changes only**: agents spawned (PR, process id, model), rows added / icons changed / rows removed, pads archived, agents closed, merge confirmations, reconcile results, board counts.

**Never summarise review findings** — no recap, no critical-issue list, no before/after numbers, no quoting the agent's reasoning. The icon plus the solo link *is* the report; the user clicks through or asks the agent. The one exception: if the user **explicitly asks** what a review found, read that pad and answer them.

---

## Standing rules

- Never open a review, reconcile, or sweep unless the user asks.
- Send review tasks verbatim — never append your own areas of concern, hypotheses, or things to watch for. You haven't read the diff; the agent will. The only permitted addition is a concern the **user** stated, passed through as one attributed line.
- Track agents in KV, never in the pad's Notes.
- Count with `scratchpad_find`, never from memory.
- Verify before recording a verdict; a timer firing is not completion.
- Keep review agents running after they finish.
- Update the master pad after any state change — Title cells hold titles only, Notes holds durable facts only. History belongs in neither the pad nor your chat output.
- When an agent relays a PR state change ("merged", "closed"), verify with `gh pr view` and act on it.
