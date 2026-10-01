# Troubleshooting

## The timer is a nudge to go look, never evidence of completion

Treat every wake-up as "something may have finished" and run `board`, which only clears ⏳ once the agent's pad exists with a parseable `Verdict:` line. Routine failure modes:

- **Freshly-spawned agents are reported "already idle" at arming time** — they hadn't picked up their input yet, so the timer excludes them and fires long before they're done.
- **The timer fires on its `max_wait_ms` deadline** rather than on completion, and says so in the delivered text.
- **Delivered bodies arrive truncated to their tail.** Keep bodies short; if a wake-up looks like a fragment, just run `board`.

## A row stays ⏳

`board` prints one line per ⏳ row. The agent is running but hasn't written its pad — `get_process_output(process_id=...)` before anything else:

- **Output shows a completed analysis** (or a sleep/API error after one) → the findings are still in its context. Send a short "your findings never reached the pad — write it now in the `security-advisory-draft` scratchpad format, including the `Verdict:` line, then send your Draft landed ping". Re-running the analysis would waste work it already did, and on Opus that's expensive.
- **Output shows it asking a question** → it's blocked on something only the user knows. Relay the question; don't answer it yourself. Re-arm the backstop after the answer goes back.
- **Parked on a permission prompt** → tell the user; don't answer it for them.
- **Output is blank or it never started** → close it and `spawn` again.

A ⏳ row whose agent has died disappears from the board on the next `board` run (no pad, no running agent). Tell the user, and `spawn` again if they want it redone.

## `ERROR` lines from `board`

The script leaves that row as it was and exits non-zero rather than guess.

- **`no parseable Verdict line`** → the pad doesn't follow the `security-advisory-draft` scratchpad format, or the agent wrote it before finishing. Ask its agent (if running) to fix the metadata block, or tell the user.
- **`ambiguous advisory pads …`** → more than one pad claims to be that GHSA's. The script ignores pads tagged `second-opinion` and prefers `Advisory <GHSA> — <current summary>`. Tell the user which pads collide; the fix is to tag the extra one `second-opinion` or rename it.

## `WARN` lines

- **`pads for GHSAs not found in <repo>`** → a pad names a GHSA this repo doesn't have (typo, or the wrong checkout). Tell the user; the script never touches it.
- **`agent … matches GHSA-…, GHSA-…`** → two advisories in the repo share a first block, so the agent's name can't say which it belongs to. The script ignores that agent: `reconcile` won't close it and `spawn` won't see it. Tell the user, and close it by hand once its advisory is done.

## Two agents on one advisory

`reconcile` flags it with both ids, oldest first, and `spawn` refuses that advisory until it's resolved. Ask the user which to keep — usually theirs — and close the other.

## An agent wrote to GitHub

It shouldn't — the constraint leads its task. If it happens anyway, tell the user immediately and plainly, with what was written and where. Don't try to undo it yourself; reverting a GHSA state change is its own write.
