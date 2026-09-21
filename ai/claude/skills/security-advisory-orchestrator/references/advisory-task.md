# Sending the advisory task

## Send it in two messages

A long first paste to a freshly-spawned agent **gets truncated by its startup banner** — the agent receives only the tail, and either sits idle or replies "your message looks like it got cut off". The submission content makes this task long by definition, so the split is not optional here.

Use `wait_ms` on **message 1 only**: it returns ~50 lines of rendered terminal (banner, ANSI boxes, status line), worth paying once to catch truncation and pure waste afterwards. If the echo shows a truncated message, re-send it shorter. Later messages are safe — the truncation only affects the first message to a cold agent.

(Believed to be a Solo bug rather than permanent behaviour. If a first paste is ever observed to survive intact, this split collapses to one message — so don't build further structure on top of it.)

## Send it verbatim

**Do not add your own analysis.** No "this looks like it's really a duplicate of…", no severity guess, no hypothesis about the root cause, no "I don't think this is exploitable". You have read the report as text; the agent will read the code. Your framing biases its finding, and a security judgement anchored on a guess is worse than no anchor.

The only permitted addition is context the **user** supplied — pass it through verbatim as an attributed line.

## Message 1 — short

```
send_input(process_id=<id>, wait_ms=2500, input="You're the advisory agent for <ID> in <OWNER/REPO> (cwd <PWD>). A vulnerability report is coming in my next message. Read-only: you may not create, edit or publish anything on GitHub — your output goes to a Solo scratchpad only.")
```

The read-only constraint goes in **message 1**, before the agent has anything to act on. It is the one instruction that must never be the part that got truncated.

## Message 2 — the submission and the tasks

```
send_input(process_id=<id>, input="""
Here's the submission, and what I need from you.

## Submission (source: <GHSA | Pasted | File>)

<FULL SUBMISSION CONTENT — the GHSA JSON, the pasted report, or the file contents>

## Your tasks

1. **Analyse the submission.** Consider:
   - What is the vulnerability class and root cause?
   - Who can exploit it, and under what conditions?
   - What is the actual impact (data exposure, privilege escalation, denial of service, etc.)?
   - What versions are affected?
   - Is the reported CVSS/CWE accurate? If not, what would you assign and why?
   - Are there any gaps, inconsistencies, or unclear claims in the report?
   - Is this actually a valid vulnerability at all — or a duplicate, a non-issue, or something already mitigated?

2. **Draft the advisory** using the `security-advisory-draft` skill. Pass it the full submission content and the working directory context.

3. **Write your findings to a Solo scratchpad** titled exactly `Advisory <ID> — <short summary>`, with this structure:
   ```
   ## Analysis
   [Your full analysis from task 1]

   ## Advisory Draft
   [The security-advisory-draft output — title, description, CVSS, CWE, affected versions, patched versions]

   ## Verdict
   Valid | Duplicate | Not a vulnerability | Already mitigated — plus the severity you assigned, in one line.
   ```
   Create it with: scratchpad_write(project_id=<PROJECT_ID>, name="Advisory <ID> — <short summary>", content=<your findings>)

   Write the `## Advisory Draft` heading only when there is a draft under it. The orchestrator uses that section's presence to tell a finished analysis from one that stopped halfway. If you conclude it isn't a valid vulnerability, say so under that heading rather than leaving it empty.

4. **Tag the scratchpad:** ["advisory", "security", "<id-slug>"]
   e.g. ["advisory", "security", "ghsa-1234-5678-9abc"] or ["advisory", "security", "adv-2026-01"]

5. **Read-only, strictly.** Do not create, edit, publish, withdraw or otherwise change any GitHub security advisory, issue, PR or comment. Read-only `gh` calls are fine. Everything you produce goes in the scratchpad; the user decides what reaches GitHub.

6. **Do NOT exit when the analysis is done.** Stay running and idle. You are the discussion thread for this advisory — the user may want to iterate on the draft, challenge your analysis, or add context.

7. **Your scratchpad is the single source of truth.** If discussion changes your verdict or your draft, edit the scratchpad to match, then notify the orchestrator so it can update the master table — send it a message via a Solo timer delivered to its process:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="Advisory <ID> updated. Re-read its `Advisory <ID>` scratchpad and update its row in the master table.")
   The orchestrator's process id is in the Solo KV store: kv_get(key="security_advisory_orchestrator_process_id"). Do this every time, not just the first.

8. **Relay state changes the user tells you about.** You are one agent in a fleet; the orchestrator tracks the whole board and cannot see your conversation. If the user tells you anything that changes this advisory's state — "I've published this", "I'm closing it as invalid", "this is a duplicate of the other one", "we're not fixing it" — do NOT just acknowledge it. Relay it immediately, the same way:
   timer_set(delay_ms=1000, delivery_process_id=<orchestrator process id>, body="Advisory <ID> update: <what the user told you>. <Anything the orchestrator should do, e.g. 'Run cleanup.'>")
   Then confirm to the user that you've passed it on. Relaying is cheap; a stale master table is not. When in doubt, relay.

Working directory: <PWD>
Repository: <OWNER/REPO>
""")
```

## Reconnecting to an existing agent

If a pad already exists and its agent is still running (resolve it per the skill's agent registry), don't spawn a second one. Forward the user's message with `send_input` and relay the reply — the running agent already has the report and its own reasoning loaded.
