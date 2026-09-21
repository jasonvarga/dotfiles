# Troubleshooting

## The timer is a nudge to go look, never evidence of completion

Treat every wake-up as "something may have finished", and verify. Routine failure modes:

- **Freshly-spawned agents are reported "already idle" at arming time** — they hadn't picked up their input yet, so the timer excludes them from the wait. With `timer_fire_when_idle_any` the response says `already_idle` and notes the timer will now only fire at `max_wait_ms`. Don't wait on it: `timer_cancel` and harvest immediately. `get_process_status` showing `agent_state.idle: true` with a non-trivial `idle_seconds` is the same signal.
- **The timer fires on its `max_wait_ms` deadline** rather than on completion, and says so in the delivered text.
- **The delivered body arrives truncated to its tail**, so your instructions may reach you as a fragment. If a wake-up looks like a partial sentence, treat it as "harvest the batch I last spawned" and reconstruct the rest from the master table's `⏳` rows.

Idle means "worker quiet", not "task complete".

## A finished analysis is not a written one

An agent can complete its analysis, go idle, and never write its pad. Seen causes: the machine slept mid-write (`API Error: Your computer went to sleep mid-response`), or the task message was truncated and it never started.

When a pad hasn't advanced — or has `## Analysis` but no `## Advisory Draft` — check `get_process_output(process_id=...)` before doing anything else:

- **Output shows a completed analysis** (or a sleep/API error after one) → the findings are still in its context. Send a short "your findings never reached the pad — write scratchpad `<id>` now, including the `## Advisory Draft` and `## Verdict` sections". Re-running the analysis would waste work it already did, and on Opus that's expensive.
- **Output is blank, or shows a truncated first message** → it never received the task. Re-send, short, per `references/advisory-task.md`.
- **Output shows it asking a question** → it's blocked on something it needs from the user. Relay the question; don't answer it yourself and don't guess. Re-arm the timer after the answer goes back.

Do not flip the row to `📝` in any of these cases, and do not re-arm-and-forget: an advisory stuck at `⏳` with nobody watching is the failure this timer exists to prevent.

## An agent is Running but nothing is happening

Running is not working. An agent can be Running and idle but parked — on a permission prompt, or waiting on a tool it can't reach. Only `get_process_output` shows this. Check it when a nudge produces no pad revision bump.

## Two agents on one advisory

A KV miss where the user had spawned an agent themselves leads you to spawn a second onto the same pad. Only reconcile's `list_processes` pass catches it. Close the one you spawned, keep the user's, and `kv_set` the survivor.

## An agent wrote to GitHub

It shouldn't be able to reach that path — the constraint is in message 1 and again in the task. If it happens anyway, tell the user immediately and plainly, with what was written and where. Don't try to undo it yourself; reverting a GHSA state change is its own write.
