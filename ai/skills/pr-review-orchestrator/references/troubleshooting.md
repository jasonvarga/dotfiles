# Troubleshooting

## The timer is a nudge to go look, never evidence of completion

Treat every wake-up as "something may have finished", and verify. Routine failure modes:

- **Freshly-spawned agents are reported "already idle" at arming time** — they hadn't picked up their input yet, so the timer excludes them from the wait and can fire long before they're done.
- **The timer fires on its `max_wait_ms` deadline** rather than on completion, and says so in the delivered text.
- **The delivered body arrives truncated to its tail**, so your instructions may reach you as a fragment. If a wake-up looks like a partial sentence, treat it as "harvest the batch I last spawned" and reconstruct the rest from the master table's `⏳` rows.

## A finished review is not a written review

An agent can complete its analysis, go idle, and never write its pad. Seen causes: the machine slept mid-write (`API Error: Your computer went to sleep mid-response`), or the task message was truncated and it never started.

When a pad hasn't advanced, check `get_process_output(process_id=...)` before doing anything else:

- **Output shows a completed review** (or a sleep/API error after one) → the findings are still in its context. Send a short "your findings never reached the pad — write scratchpad `<id>` now, including the `## Verdict` and the marker first line". Re-running the whole review would waste work it already did.
- **Output is blank, or shows a truncated first message** → it never received the task. Re-send it, short, per `references/review-task.md`.
- **Output shows it asking to switch models** → the model router parked it: message 1 went out without naming a model, or the router disagreed with the model you spawned. Close it and respawn on the model it asked for, naming it this time.

## An agent is Running but nothing is happening

Running is not working. An agent can be Running and idle but parked — at the `review` skill's model router, or on a permission prompt. Only `get_process_output` shows this. Check it when a nudge produces no pad revision bump.

## Two agents on one PR

The worst failure in this flow and invisible to KV: a KV miss where the user had spawned an agent themselves leads you to spawn a second onto the same pad. Only reconcile's `list_processes` pass catches it. Close the one you spawned, keep the user's, and `kv_set` the survivor.
