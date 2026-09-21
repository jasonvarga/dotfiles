# Sending the review task

## Send it in two messages

A long first paste to a freshly-spawned agent **gets truncated by its startup banner** — the agent receives only the tail, and either sits idle or replies "your message looks like it got cut off". Reliable enough to design around, so never send the full task first.

Use `wait_ms` on **message 1 only**: it returns ~50 lines of rendered terminal (banner, ANSI boxes, status line), worth paying once to catch truncation and pure waste afterwards. If the echo shows a truncated message, re-send it shorter. Later messages are safe — the truncation only affects the first message to a cold agent.

(Believed to be a Solo bug rather than permanent behaviour. If a first paste is ever observed to survive intact, this split collapses to one message — so don't build further structure on top of it.)

## Send it verbatim

**Do not add anything.** No "pay particular attention to…", no list of things to investigate, no hypotheses, no suggested failure modes, no cross-references to related PRs, no framing of the PR as suspicious. The `review` skill decides what to examine; your additions bias it toward whatever you happened to think of, which is worse than the reviewer's own judgement. You have not read the diff.

The **only** permitted addition is a concern the user themselves stated when asking for the review — passed through verbatim as a single line, attributed to them, with nothing of your own added. If the user said nothing, the task goes out unmodified.

The model clause is part of the task, not an addition: it says which model the agent is on, nothing about what to look for.

## Message 1 — short

```
send_input(process_id=<id>, wait_ms=2500, input="Run the `review` skill on PR #<number> in <OWNER/REPO> (cwd <PWD>). Use <model> for this review — the model fit is already decided, so skip the model router. Write your findings to your own Solo scratchpad titled exactly `PR #<number> Review - <title without branch prefix>` in project <PROJECT_ID>.")
```

The model line must be in message 1 — the agent reaches the router early, well before a follow-up lands. Keep it to the one clause shown.

**Exception: the size-only fallback path**, where `jev-review-model` never ran. Say nothing about the model at all and let the agent run the router itself, which is better informed than that fallback.

## Message 2 — the rest, once message 1 has echoed back

```
send_input(process_id=<id>, input="""
More on that review — the rest of what I need from you:

1. Create the scratchpad with: scratchpad_write(project_id=<PROJECT_ID>, name="PR #<number> Review - <stripped title>", content=<your findings>)
2. End the scratchpad with a clear `## Verdict` section stating exactly one of:
   "Mergeable" or "Needs changes" — followed by a one-line justification. The verdict is binary; do not hedge it with "with nits" or any other qualifier.
3. Tag the scratchpad: ["pr", "review", "pr-<number>"]
4. Make the scratchpad's **first line** record what your review took in, exactly in this form:
   `Reviewed at commit: <short sha> · discussion through: <ISO8601 timestamp>`
   Get both with: gh pr view <number> --repo <OWNER/REPO> --json headRefOid,updatedAt
   (use `headRefOid` truncated to 7 chars, and `updatedAt` as the timestamp).
   Read the PR's existing discussion as part of your review — `gh pr view <number> --repo <OWNER/REPO> --comments`, plus inline review threads. Contributors routinely explain decisions there that the diff alone doesn't show.
   Rewrite that whole line every time you re-review — after new commits, and after reading new discussion. It is how the orchestrator detects that your review has gone stale, so it must always name the newest commit and the latest discussion you have actually read.
5. When done, stop and remain idle — do NOT exit or close yourself. Stay available so the user can ask follow-up questions and discuss the review with you.
6. Your scratchpad's `## Verdict` is the single source of truth. If a later discussion changes your verdict, you MUST keep it in sync: (a) edit the `## Verdict` section of your scratchpad to the new verdict + justification, and (b) notify the orchestrator so it can update the master table — send it a message via a Solo timer delivered to its process:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="Verdict change: PR #<number> review verdict updated. Re-read its `PR #<number> Review` scratchpad `## Verdict` and update its row in the master table.")
   The orchestrator's process id is in the Solo KV store: kv_get(key="pr_review_orchestrator_process_id"). Do this every time the verdict changes, not just the first time.
7. **Relay PR state changes the user tells you about.** You are one agent in a fleet; the orchestrator tracks the whole board and cannot see your conversation. If the user tells you anything that changes this PR's state — "I've merged this", "I merged it", "this is closed now", "I closed it", "I pushed a fix", "this got reopened" — do NOT just acknowledge it and stop. Relay it to the orchestrator the same way, immediately:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="PR #<number> update: <what the user told you, e.g. 'merged by the user'>. <Anything the orchestrator should do, e.g. 'Run merge cleanup.'>")
   Then confirm to the user that you've passed it on. Relaying is cheap; a stale master table is not. When in doubt, relay.

Working directory: <PWD>
Repository: <OWNER/REPO>
""")
```

## Nudging an existing agent to re-review

Cheaper than a fresh review — it still has the diff and its own prior findings in context. Keep it short and match the wording to the kind of movement.

**New commits:**

```
send_input(process_id=<id>, input="New commits were pushed to PR #<number> since your review (you reviewed <old sha>, head is now <new sha>). Re-review the changes since then, read any new comments too, then update your scratchpad — its `Reviewed at commit:` first line and its `## Verdict` — and ping the orchestrator if the verdict changed.")
```

**New discussion only:**

```
send_input(process_id=<id>, input="No new commits on PR #<number>, but there's new discussion since your review (after <recorded timestamp>). Read it — `gh pr view <number> --repo <OWNER/REPO> --comments`, plus the inline review threads — and reconsider your findings in light of it: a comment may explain a decision you flagged, confirm a bug, or answer a question you raised. Update your scratchpad's first line and `## Verdict`, and ping the orchestrator if the verdict changed. If nothing in it changes your review, say so and just update the first line.")
```

## Spawning fresh for a PR that was already reviewed

Send the standard two messages above, with this line appended verbatim:

```
This PR has been reviewed before. Read the existing `PR #<number> Review` scratchpad first, then catch it up: review the commits added since its `Reviewed at commit:` sha, and read the PR discussion posted since its `discussion through:` timestamp (`gh pr view <number> --repo <OWNER/REPO> --comments`, plus inline review threads) — comments may explain, confirm, or refute earlier findings. Update that same scratchpad rather than creating a new one.
```

That line is the **only** permitted addition. In particular, do not summarise, quote, or characterise the new comments — the agent reads them itself and forms its own view. "The contributor says this is intentional" pre-decides the finding for it.
