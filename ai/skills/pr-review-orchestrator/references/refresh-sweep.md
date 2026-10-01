# Refresh sweep

A review goes stale when the PR moves under it — new commits **or** new discussion. Comments are not noise: a contributor explaining *why*, a maintainer clarifying intended behaviour, an answer to a question the review raised can each resolve or invalidate a finding. The sweep finds every board PR that has moved and brings its review up to date, so the user never has to notice a push themselves.

Never run unprompted.

## 1. Plan

Read the pad's Notes section for PRs excluded from sweeps, then:

```
pr-orch sweep-plan [pr...] --exclude <n,n>
```

Pass PR numbers only if the user named specific ones. The script compares each pad's `Reviewed at:` line with the PR's head and confirms new discussion is real (human, newer than the recorded timestamp, not the user's own posted reviews). It prints three lists — new commits, new discussion, merged/closed — and one action line per moved PR.

Report the three lists (PR numbers only). If the script says there are more than 10 to do, **stop and ask which to do**. Otherwise carry on without asking — that's the point of the sweep. Merged/closed PRs → `pr-orch reconcile --apply`.

## 2. Bring each up to date, five at a time

Work in **batches of five**: a big fan-out competes for the same machine, and a failure in one is easy to lose among twenty.

For each PR in the batch:

- **`nudge (agent <id>)`** → collect them into one `pr-orch nudge <n> <n> …`, then `send_input` each printed text, unmodified, to the agent it names. Don't summarise, quote or characterise the new commits or comments — the agent reads them itself.
- **`spawn --refresh`** → `pr-orch spawn <n> --refresh --label "<label>"`, labelling it from the title on the action line. Note the process id — it's a sweep agent.

Both mark the row ⏳ until the pad catches up. Arm `timer_fire_when_idle_all` over the batch's agents with `max_wait_ms=900000`. Pings (`Review landed`) and the timer both mean `pr-orch board`; start the next batch once the current one has landed or the timer fires.

## 3. Close, finish

**Whole-board sweeps only** (no PR numbers named): close each agent the sweep spawned (`close_process`) once its row has left ⏳. If the user named the PRs, it's a re-review they asked for — leave every agent running for discussion. A sweep agent is a throwaway that exists to refresh one pad; the user can always respawn a discussion agent against the written review. **Agents that were already running are left alone** — nudging them is fine, closing them is not.

When the whole list is done: `pr-orch board --mark-refreshed`, confirm no ⏳ rows remain, and report which PRs were re-reviewed and which icons changed — never what changed in them.
