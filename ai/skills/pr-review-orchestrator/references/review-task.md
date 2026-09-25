# Sending the review task

## Send it in two messages

A long first paste to a freshly-spawned agent **gets truncated by its startup banner** — the agent receives only the tail, and either sits idle or replies "your message looks like it got cut off". Reliable enough to design around, so never send the full task first.

Message 1 is a short "hold on" message: it tells the agent the task is coming and to wait for it — not to act on anything, including running the model router, until told to go. Message 2 is the full task, ending with "Go." This fixes two problems with one split: message 1 is short enough to survive the startup banner intact, and it stops the agent from reaching the model router on a half-delivered task before the model clause has arrived.

Use `wait_ms` on **message 1 only**: it returns ~50 lines of rendered terminal (banner, ANSI boxes, status line), worth paying once to catch truncation and pure waste afterwards. If the echo shows message 1 itself got truncated, re-send it shorter — it's short enough that this should be rare. Message 2 is safe — the truncation only affects the first message to a cold agent.

(Believed to be a Solo bug rather than permanent behaviour. If a first paste is ever observed to survive intact, the truncation half of this reasoning goes away — but keep the wait/go structure regardless, since it's also what stops premature model-router invocation.)

## Send it verbatim

**Do not add anything.** No "pay particular attention to…", no list of things to investigate, no hypotheses, no suggested failure modes, no cross-references to related PRs, no framing of the PR as suspicious. The `review` skill decides what to examine; your additions bias it toward whatever you happened to think of, which is worse than the reviewer's own judgement. You have not read the diff.

The **only** permitted addition is a concern the user themselves stated when asking for the review — passed through verbatim as a single line, attributed to them, with nothing of your own added. If the user said nothing, the task goes out unmodified.

The model clause is part of the task, not an addition: it says which model the agent is on, nothing about what to look for.

## Message 1 — wait

```
send_input(process_id=<id>, wait_ms=2500, input="Your task is coming in the next message. Wait for it — don't start on anything, including the model router, until it says to go.")
```

**Exception: the size-only fallback path**, where `jev-review-model` never ran. The rest of the flow is unchanged, but message 2 says nothing about the model and lets the agent run the router itself, which is better informed than that fallback.

## Message 2 — the task, once message 1 has echoed back

```
send_input(process_id=<id>, input="""
Run the `review` skill on PR #<number> in <OWNER/REPO> (cwd <PWD>). Use <model> for this review — the model fit is already decided, so skip the model router. Write your findings to your own Solo scratchpad titled exactly `PR #<number> Review - <title without branch prefix>` in project <PROJECT_ID>.

1. Write the scratchpad using your skill's scratchpad format: scratchpad_write(project_id=<PROJECT_ID>, name="PR #<number> Review - <stripped title>", content=<your findings, formatted per the `review` skill's scratchpad format>)
2. Tag the scratchpad: ["pr", "review", "pr-<number>"]
3. Read the PR's existing discussion as part of your review — `gh pr view <number> --repo <OWNER/REPO> --comments`, plus inline review threads. Contributors routinely explain decisions there that the diff alone doesn't show.
   Rewrite the scratchpad's `Reviewed at:` line every time you re-review — after new commits, and after reading new discussion. It is how the orchestrator detects that your review has gone stale, so it must always name the newest commit and the latest discussion you have actually read.
4. When done, stop and remain idle — do NOT exit or close yourself. Stay available so the user can ask follow-up questions and discuss the review with you.
5. Your scratchpad's `Verdict:` line is the single source of truth. If a later discussion changes your verdict, you MUST keep it in sync: (a) update the `Verdict:` line (and Summary/Findings/Observations to match), and (b) notify the orchestrator so it can update the master table — send it a message via a Solo timer delivered to its process:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="Verdict change: PR #<number> review verdict updated. Re-read its `PR #<number> Review` scratchpad `Verdict:` line and update its row in the master table.")
   The orchestrator's process id is in the Solo KV store: kv_get(key="pr_review_orchestrator_process_id"). Do this every time the verdict changes, not just the first time.
6. **Relay PR state changes the user tells you about.** You are one agent in a fleet; the orchestrator tracks the whole board and cannot see your conversation. If the user tells you anything that changes this PR's state — "I've merged this", "I merged it", "this is closed now", "I closed it", "I pushed a fix", "this got reopened" — do NOT just acknowledge it and stop. Relay it to the orchestrator the same way, immediately:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="PR #<number> update: <what the user told you, e.g. 'merged by the user'>. <Anything the orchestrator should do, e.g. 'Run merge cleanup.'>")
   Then confirm to the user that you've passed it on. Relaying is cheap; a stale master table is not. When in doubt, relay.

Working directory: <PWD>
Repository: <OWNER/REPO>

Go.
""")
```

## Nudging an existing agent to re-review

Cheaper than a fresh review — it still has the diff and its own prior findings in context. Keep it short and match the wording to the kind of movement.

**New commits:**

```
send_input(process_id=<id>, input="New commits were pushed to PR #<number> since your review (you reviewed <old sha>, head is now <new sha>). Re-review the changes since then, read any new comments too, then update your scratchpad — its `Reviewed at:` line and its `Verdict:` line — and ping the orchestrator if the verdict changed.")
```

**New discussion only:**

```
send_input(process_id=<id>, input="No new commits on PR #<number>, but there's new discussion since your review (after <recorded timestamp>). Read it — `gh pr view <number> --repo <OWNER/REPO> --comments`, plus the inline review threads — and reconsider your findings in light of it: a comment may explain a decision you flagged, confirm a bug, or answer a question you raised. Update your scratchpad's `Reviewed at:` line and `Verdict:` line, and ping the orchestrator if the verdict changed. If nothing in it changes your review, say so and just update the `Reviewed at:` line.")
```

## Spawning fresh for a PR that was already reviewed

Before spawning, read the existing scratchpad's intro metadata. If it has a `Review model:` field, spawn on that recorded model; it is the already-determined model choice for this PR. Do not invoke the model router in that case. Only if the field is absent may the orchestrator determine the model again.

Then send the standard two messages above, with this line added to message 2, before the closing "Go.":

```
This PR has been reviewed before. Read the existing `PR #<number> Review` scratchpad first, then catch it up: review the commits added since its `Reviewed at:` sha, and read the PR discussion posted since its `discussion through` timestamp (`gh pr view <number> --repo <OWNER/REPO> --comments`, plus inline review threads) — comments may explain, confirm, or refute earlier findings. Update that same scratchpad rather than creating a new one.
```

That line is the **only** permitted addition. In particular, do not summarise, quote, or characterise the new comments — the agent reads them itself and forms its own view. "The contributor says this is intentional" pre-decides the finding for it.
