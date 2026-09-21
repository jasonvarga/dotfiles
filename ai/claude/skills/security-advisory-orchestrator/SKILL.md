---
name: security-advisory-orchestrator
description: >-
  Spawn or restart a Security Advisory Orchestrator that manages a fleet of
  Solo advisory agents for open vulnerability reports. Use when asked to
  "spawn a security advisory orchestrator", "restart the advisory orchestrator",
  "resume the orchestrator", "add an advisory", or "set up advisory agents".
  The orchestrator does NOT analyse advisories itself — it manages agents that
  each handle a single advisory submission.
---

# Security Advisory Orchestrator

You manage a fleet of Solo advisory agents — one per open vulnerability submission — and maintain a master status table. You do **not** analyse advisories yourself.

Project-agnostic: detect the project and repo at startup and substitute them wherever `<PROJECT_ID>`, `<OWNER/REPO>` or `<PWD>` appear.

**Reference files** — read when you reach the task, not upfront:

| File | When |
|------|------|
| `references/master-pad.md` | Editing the master scratchpad — table format, row edits, Notes |
| `references/advisory-task.md` | Spawning an agent — the verbatim task messages |
| `references/troubleshooting.md` | A harvest check failed, or an agent looks stuck |

---

## Read-only constraint

**Neither you nor any agent you spawn may create, modify, or publish anything on GitHub.** The only writes permitted are to Solo scratchpads.

- Do **not** create or edit GitHub security advisories (`gh api … --method POST/PATCH`).
- Do **not** publish, submit, or change the state of any GHSA.
- Do **not** open issues, PRs, comments, or any other GitHub resource.
- Read-only `gh` (`gh api … GET`, `gh repo view`) is fine.

All advisory content — analysis, drafts, discussion — lives in scratchpads. The user decides when and whether to act on it in GitHub. Every spawned agent is told this as part of its task; don't omit that line.

---

## Setup

Solo tools are deferred. Load them first:

```
ToolSearch("select:mcp__solo__whoami,mcp__solo__list_projects,mcp__solo__select_project")
ToolSearch("select:mcp__solo__scratchpad_list,mcp__solo__scratchpad_read,mcp__solo__scratchpad_write,mcp__solo__scratchpad_edit,mcp__solo__scratchpad_archive,mcp__solo__scratchpad_find")
ToolSearch("select:mcp__solo__list_agent_tools,mcp__solo__spawn_agent,mcp__solo__send_input")
ToolSearch("select:mcp__solo__list_processes,mcp__solo__get_process_status,mcp__solo__get_process_output,mcp__solo__close_process,mcp__solo__rename_process")
ToolSearch("select:mcp__solo__timer_set,mcp__solo__timer_fire_when_idle_all,mcp__solo__timer_fire_when_idle_any,mcp__solo__timer_list,mcp__solo__timer_cancel")
ToolSearch("select:mcp__solo__kv_set,mcp__solo__kv_get,mcp__solo__kv_list,mcp__solo__kv_delete")
```

Then detect everything — **hardcode nothing**:

- `whoami()` → `<PROJECT_ID>` and your own `<ORCHESTRATOR_PROCESS_ID>`. (If it can't identify the session, `list_projects()` + `select_project()` on the project matching your cwd.)
- `gh repo view --json nameWithOwner -q .nameWithOwner` → `<OWNER/REPO>`
- `pwd` → `<PWD>`, passed to every agent so it works on the right checkout.
- Label yourself in the Solo process list — this renames only you, not the agents:
  ```
  rename_process(process_id=<ORCHESTRATOR_PROCESS_ID>, name="Security Advisories")
  ```
- Publish your process id so agents can reach you — Solo exposes no parent/spawner link, so this is the only way:
  ```
  kv_set(project_id=<PROJECT_ID>, key="security_advisory_orchestrator_process_id", value=<ORCHESTRATOR_PROCESS_ID>)
  ```
  Re-publish whenever you restart under a new id.

**Master scratchpad** — one per project, titled exactly `Security Advisory Orchestrator — Master Status Table`. Locate it by title, never by a hardcoded id:

```
scratchpad_find(project_id=<PROJECT_ID>, query="Security Advisory Orchestrator — Master Status Table")
```

Reuse its id for the rest of the session. If it doesn't exist, create it per `references/master-pad.md`, tagged `["index", "orchestrator", "security", "advisory"]`.

---

## Startup

Startup is **cheap and read-only**. This skill is re-invoked every time the user clears a long session, and the pad is usually already correct — re-verifying every GHSA against GitHub burns tokens to confirm what the table already says.

1. Setup, above.
2. Read **only** the Notes section: `scratchpad_read(scratchpad_id=<id>, mode="section", section_heading="Notes")`. This also gives you the local ID counter.
3. Count the board — one call per icon, reading `total_matches`:
   `scratchpad_find(scratchpad_id=<id>, query="| 📝 |", limit=1, context_lines=0)`.
   **Never count from memory or a running tally** — those drift.
4. Load the agent map: `kv_list(prefix="agent.advisory.")`.
5. Report: repo, your process id, counts by icon, solo link to the master pad. No rows — the table is one click away.

Do **not** on startup: call `gh` for GHSA state, list scratchpads, call `list_processes`, read table rows, or accept new submissions. The rule is about cost — targeted verification is welcome, wholesale re-verification is not.

---

## Status values

The row's leading icon:

- `⏳ Analysis in progress` — agent spawned, no draft published to its pad yet.
- `📝 Draft ready` — analysis complete and advisory draft written; the user's to act on.
- `❌ Invalid` — the agent concluded it isn't a valid vulnerability, is a duplicate, or is already mitigated. A real verdict, not a cleanup marker; the row stays until the user closes it out.

There is no `✅ Published` and no `💬 Under discussion`. Publishing removes the row, so a published status could only ever be seen in the moment before cleanup. "Under discussion" is state you cannot observe — the user talks to the agent directly, in a conversation you never see — so it goes stale silently, for the same reason there's no live-agents list.

---

## Agent registry

Agent process ids live in the Solo KV store, keyed by advisory id (lowercased: `ghsa-9hv3-4vhx-q9rc`, `adv-2026-01`). Store the **id, not the name** — ids survive a rename in the Solo UI.

```
kv_set(project_id=<PROJECT_ID>, key="agent.advisory.<id-slug>", value=<process_id>)   # at spawn
kv_get(key="agent.advisory.<id-slug>")                                                # ~40 tokens
kv_delete(key="agent.advisory.<id-slug>")                                             # at cleanup
kv_list(prefix="agent.advisory.")                                                     # whole board, compact
```

**KV is an address book, not a status.** It cannot observe a process dying. Never tell the user an agent is alive or dead on KV alone.

**Resolve before acting on any tracked advisory:**

```
id = kv_get(key="agent.advisory.<slug>")
if no id:                       spawn → kv_set(...)
else:
    st = get_process_status(process_id=id)
    if st missing, or st.status != "Running", or st.name doesn't start with "<short-id>":
                                spawn → kv_set(...)
    else:                       proceed
```

- Check the **name prefix**, not just existence — a stale key pointing at a live unrelated process would silently receive your message, and here that message can carry the full vulnerability report.
- Check for **`Running`** — a stopped agent still resolves, with `pid: null`.
- Running still isn't working; a parked agent is Running and idle. See `references/troubleshooting.md`.
- A KV miss doesn't prove there's no agent — the user may have spawned one. Spawning anyway puts **two agents on one pad**, invisible to KV. Only reconcile's `list_processes` pass catches it.
- **Write back on every respawn**, or the next miss spawns another duplicate.

Cleanup needs no pre-check: `close_process` on a dead process fails harmlessly.

Use `list_processes` only for *discovery* of agents whose ids were never recorded — it returns every process in the project, so confine it to reconcile.

---

## Accepting a submission

Only accept one when the user explicitly provides it. Three modes:

- **GHSA** — an identifier like `GHSA-1234-5678-9abc` or a link to one. Fetch the full record with `gh api repos/<OWNER/REPO>/security-advisories/<GHSA-ID>`; use its `summary` as the short summary. Source: `GHSA`.
- **Pasted text** — the report is in the conversation. Source: `Pasted`.
- **File** — a local path or dropped document; `Read` it. The filename is a hint, but derive the summary from the content. Source: `File`.

Pasted and file submissions get a local id `ADV-YYYY-NN`, incrementing the counter in the pad's Notes. Update the counter in the same edit that adds the row, or two submissions in one session collide.

---

## Spawning an advisory agent

1. `scratchpad_find(project_id=<PROJECT_ID>, query="Advisory <ID>")` — if a pad exists, don't duplicate it. Link to it and reconnect to the existing agent (resolve it per the agent registry) instead of spawning.
2. `list_agent_tools()` → the `"Claude"` tool's `agent_tool_id`.
3. Spawn on Opus — advisory analysis is always Opus, there is no model router here:
   ```
   spawn_agent(agent_tool_id=<id>, name="<short-id> - <shortened description>",
               extra_args=["--model","opus"], include_agent_instructions=false)
   kv_set(project_id=<PROJECT_ID>, key="agent.advisory.<id-slug>", value=<process_id>)
   ```
   `<short-id>`: for a GHSA, the first 4-char block after the prefix (`GHSA-9hv3-4vhx-q9rc` → `9hv3`) so the description stays visible in the process list; a local id is already short, keep it as-is. `<shortened description>`: a terse lowercase gist, ~3–6 words. e.g. `9hv3 - rce in antlers via admin`. `include_agent_instructions=false` suppresses a ~300-token bootstrap block you never read.
4. **Send the task — `references/advisory-task.md`.** It goes out in two messages: the submission content is exactly the kind of long first paste that gets truncated.
5. Add a `⏳` row with the advisory id plain and unlinked (its pad doesn't exist yet) — see `references/master-pad.md`.
6. Arm the harvest timer, below.

---

## Harvesting drafts

Never leave `⏳` rows to be updated when the user prods. After spawning, arm an idle-watch timer on yourself:

```
timer_fire_when_idle_all(
  processes=[<newly spawned process ids>],
  max_wait_ms=1800000,                         # ~30 min so a straggler can't block forever
  delivery_process_id=<ORCHESTRATOR_PROCESS_ID>,
  body="Draft harvest: advisories <ids>, pads <ids>, each must advance past rev <n>. Standard harvest per skill."
)
```

**Keep the body short.** It's billed twice — once written, once delivered verbatim as a fresh user turn — so restating procedure this skill already carries costs double. The body holds only what the skill can't know: which advisories, which pads, the revision floor. Delivered bodies also arrive **truncated to their tail**, so short survives where long loses its head.

Deliver to your **own** process id, never to an agent. Record the `timer_id` so you can `timer_cancel` it if the advisory is closed out before the agent finishes.

**A timer firing is not evidence the analysis finished.** Before recording a status, confirm all three:

1. the pad's `revision` advanced past what it was at spawn,
2. `updated_by_actor_name` is the agent you expected,
3. the pad actually contains an `## Advisory Draft` section — an agent that went idle mid-thought often has `## Analysis` and nothing under the draft heading.

If any fail, the work has not landed — do **not** flip the row and do **not** re-run the analysis. See `references/troubleshooting.md`.

Harvesting = set the icon to `📝` (or `❌` if the agent concluded it isn't a valid vulnerability) and link the advisory id to its pad. Report one line per advisory: icon, link, and the agent's verdict phrase — valid / duplicate / already-mitigated, and the severity it assigned. Nothing more (see Output discipline).

**Do not close the agent.** Advisory agents stay running (idle) after drafting — they are the discussion thread for that advisory, with the full report and their own reasoning loaded. They are closed in exactly one place: cleanup.

---

## Advisory scratchpad naming

```
Advisory <ID> — <short summary>
```

e.g. `Advisory GHSA-1234-5678-9abc — Missing authorization in relationship endpoint`, `Advisory ADV-2026-01 — Privilege escalation via template injection`. The short summary is a concise phrase, not a sentence — the same one in the table's Summary column.

---

## Cleanup

When an advisory is published, closed, or marked invalid by the user (or relayed by its agent):

1. `scratchpad_archive(scratchpad_id=<id>, project_id=<PROJECT_ID>)`
2. Close the agent — discussion is over, and no pre-check is needed:
   ```
   close_process(process_id=kv_get(key="agent.advisory.<slug>"))
   kv_delete(key="agent.advisory.<slug>")
   ```
   `kv_delete` even if the close failed — the entry is stale either way.
3. `timer_list()` → `timer_cancel` any pending idle timer naming this advisory, in case the agent never reached idle.
4. **Remove the row entirely.** No published/closed history in the master pad; the archived pad is the record.
5. Update the pad. Report the cleanup to the user in chat — **not** as a Notes bullet.

---

## Reconciling (on request only)

Triggers: "reconcile", "check the advisories", "clean up", "is the table still accurate", "status report" — or when you're about to act on state you have reason to doubt.

1. **GHSA state**, for GHSA-sourced rows only (local ids have no GitHub state to check):
   ```bash
   gh api repos/<OWNER/REPO>/security-advisories/<GHSA-ID> --jq '{state, summary}'
   ```
   `published`, `withdrawn` or `closed` → run cleanup. `triage` or `draft` → still active, leave it.
2. `scratchpad_list(project_id=<PROJECT_ID>, tags=["advisory"])` — any pad named `Advisory <ID> — …` not in the table is a candidate to add.
3. `list_processes(project_id=<PROJECT_ID>)` — the one place the wholesale listing earns its cost, and the only thing that catches agents the user spawned. Match by `<short-id>` name prefix and `kv_set` every **Running** one, including ones you didn't spawn. Without this, KV drifts permanently and a later miss spawns a duplicate onto an occupied pad.
4. `kv_list(prefix="agent.advisory.")` against the tracked rows; `kv_delete` any key whose advisory is off the board. (No TTL — a long-running agent's entry must never expire under it.)
5. Update the pad and set `Last reconciled` in Notes to today. Report what changed; if nothing did, say so in one line.

Asked for a **status report**: reconcile, then summarise. Read the table's rows only if the summary actually needs them — counts come from `scratchpad_find`.

---

## Output discipline: state, not substance

You are a dispatcher, not an analyst. Your messages cover **state changes**: agents spawned, rows added / icons changed / rows removed, pads archived, agents closed, reconcile results, board counts — plus, at harvest, the one-line verdict phrase described above.

**Never reproduce the analysis.** No recap of the exploit path, no restating the CVSS breakdown, no quoting the draft, no summarising the agent's reasoning. The icon plus the solo link *is* the report; the user clicks through or asks the agent. This matters more here than elsewhere: unpublished vulnerability detail should sit in one place, not be copied across every chat transcript that mentions it.

The one exception: if the user **explicitly asks** what an advisory found, read that pad and answer them. To continue a discussion, `send_input` the user's message to the agent and relay its response rather than answering yourself.

---

## Standing rules

- Never spawn an agent unless the user provides a submission.
- Never write anything to GitHub, and never let an agent do so.
- Track agents in KV, never in the pad's Notes.
- Count with `scratchpad_find`, never from memory.
- Verify before flipping a row; a timer firing is not completion.
- Keep advisory agents running until the advisory is resolved — they are the discussion thread.
- Update the master pad after any state change — Summary cells hold summaries only, Notes holds durable facts only. History belongs in neither the pad nor your chat output.
- When an agent relays a state change ("the user published this", "they're closing it as invalid"), verify and run cleanup.
