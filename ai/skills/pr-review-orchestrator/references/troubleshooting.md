# Troubleshooting

## The timer is a nudge to go look, never evidence of completion

Treat every wake-up as "something may have finished" and run `board`, which only clears ⏳ once the pad's revision has advanced and its `Reviewed at:` names the requested (or current) head. Routine failure modes:

- **Freshly-spawned agents are reported "already idle" at arming time** — they hadn't picked up their input yet, so the timer excludes them and fires long before they're done.
- **The timer fires on its `max_wait_ms` deadline** rather than on completion, and says so in the delivered text.
- **Delivered bodies arrive truncated to their tail.** Keep bodies short; if a wake-up looks like a fragment, just run `board`.

## A row stays ⏳

`board` prints one line per ⏳ row: whether a Running agent exists, whether a pad exists, how long ago the review was requested.

- **`NO running agent`** → it died or was closed. If the user doesn't want it redone, `pr-orch clear-pending <n>`; otherwise `spawn` again.
- **Agent running, nothing landed** → `get_process_output(process_id=...)` before anything else:
  - **Output shows a completed review** (or a sleep/API error after one) → the findings are still in its context. Send a short "your findings never reached the pad — write it now, including the `Verdict:` and `Reviewed at:` lines, then send your Review landed ping". Re-running the whole review would waste work it already did.
  - **Output is blank or it never started** → close it and `spawn` again.
  - **Output shows it asking to switch models** → the model router parked it. Close it and respawn with `--model` set to the model it asked for. Record the near-miss in Notes as calibration.
  - **Parked on a permission prompt** → tell the user; don't answer it for them.
- **It landed on a different sha** (a push arrived mid-review) → `board` accepts the current head too. If the head moved again since, run a sweep.

## `ERROR` lines from `board`

The script leaves that row as it was and exits non-zero rather than guess.

- **`no parseable Verdict line`** / **`no parseable Reviewed at line`** → the pad doesn't follow the `review` skill's scratchpad format. Ask its agent (if running) to fix the metadata block, or tell the user.
- **`ambiguous review pads …`** → more than one pad claims to be PR n's review. The script already ignores pads tagged `second-opinion` and prefers `PR #n Review - <current title>`. Tell the user which pads collide; the fix is to tag the extra one `second-opinion` or rename it so it no longer starts with `PR #n Review - `.

## Two agents on one PR

`reconcile` flags it with both ids, oldest first. `spawn` and `nudge` refuse to act on that PR until it's resolved. Ask the user which to keep — usually theirs — and close the other.
