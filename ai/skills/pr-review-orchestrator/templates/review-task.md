Run the `review` skill on PR #{{number}} in {{repo}} (cwd {{pwd}}).{{modelClause}}

{{scratchpad}}
{{concern}}
You report to an orchestrator process that maintains the master status table. Its process id is in the Solo KV store: kv_get(key="pr_review_orchestrator_process_id"). Every ping below is a Solo timer delivered to that process.

1. Write the scratchpad as described above.
2. Read the PR's existing discussion as part of your review — `gh pr view {{number}} --repo {{repo}} --comments`, plus inline review threads. Contributors routinely explain decisions there that the diff alone doesn't show.
   Rewrite the scratchpad's `Reviewed at:` line every time you re-review — after new commits, and after reading new discussion. It is how the orchestrator detects that your review has gone stale, so it must always name the newest commit and the latest discussion you have actually read.
3. Every time you finish a review or re-review and have written it to the scratchpad, ping the orchestrator:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="Review landed: PR #{{number}}")
4. When done, stop and remain idle — do NOT exit or close yourself. Stay available so the user can ask follow-up questions and discuss the review with you.
5. Your scratchpad's `Verdict:` line is the single source of truth. If a later discussion changes your verdict, you MUST keep it in sync: (a) update the `Verdict:` line (and Summary/Findings/Observations to match), and (b) ping the orchestrator:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="Verdict change: PR #{{number}}")
   Do this every time the verdict changes, not just the first time.
6. Relay PR state changes the user tells you about. You are one agent in a fleet; the orchestrator tracks the whole board and cannot see your conversation. If the user tells you anything that changes this PR's state — "I've merged this", "I merged it", "this is closed now", "I closed it", "this got reopened" — do NOT just acknowledge it and stop. Relay it to the orchestrator immediately:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="PR #{{number}} update: <what the user told you, e.g. 'merged by the user'>")
   Then confirm to the user that you've passed it on. Relaying is cheap; a stale master table is not. When in doubt, relay.
7. New commits are not a state change to relay. If the user tells you commits were pushed, re-review the changes yourself — then rewrite the `Reviewed at:` line and send the "Review landed" ping as in step 3 (plus "Verdict change" if the verdict moved). That ping is all the orchestrator needs; relaying the push would only make it send you the same instruction back.

Working directory: {{pwd}}
Repository: {{repo}}
