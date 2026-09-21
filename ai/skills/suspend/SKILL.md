---
name: suspend
description: >-
  Capture the current body of work into a Solo "start here" scratchpad, record
  it in the project's suspended-work manifest, and close the agents it spawned,
  so a fresh session can pick the work up later. Use when Jason says "suspend
  this", "suspend this work", or wants to free up machine resources from work
  he isn't actively engaged in.
disable-model-invocation: true
---

# Suspend

This skill is **user-invoked only** (`disable-model-invocation: true`) — it
closes running agents, so it runs when Jason types `/suspend`, never on
Claude's own initiative.

Jason runs several bodies of work in parallel, each with its own sub-agents.
The agents for work he isn't actively engaged in sit idle for hours eating
resources. This skill writes down enough context for a fresh session to
continue, then shuts that work's agents down.

Companion skills: `/resume-work` picks a suspended body of work back up,
`/finish-work` tears one down for good.

## 0. Preconditions

Run `whoami`. It must return a Solo `process_id` with `kind: "agent"`. If it
doesn't, this isn't a Solo session — stop and say so.

This skill must only run in the **top-level** session Jason talks to. Solo
exposes no parent link between processes, so you can't detect this. Use
judgement: if you were spawned as a sub-agent — your brief arrived via
`send_input` from another agent rather than from Jason — stop and say so
rather than suspending your own parent's work.

## 1. Refuse if anything is mid-task

Suspending work that's still moving loses it. Before anything else:

1. `list_processes` to get the project's agents.
2. Narrow to the agents belonging to this body of work (section 2).
3. `get_process_status` on each and read `agent_state`.

An agent counts as **busy** if `idle` is false, `thinking` is true, or
`idle_seconds` is small enough that it's plainly mid-turn.

If any is busy: **warn and stop.** Name the busy agents and what they're
working on. Write nothing, close nothing, touch no scratchpads. Tell Jason to
run `/suspend` again once they've settled.

## 2. Identify the body of work

**The slug.** Per the Solo session hook, each body of work has a stable slug —
usually the git branch or worktree directory name. Work out this session's
slug; if it's genuinely ambiguous, ask Jason rather than guessing, since the
slug is what keeps parallel work in one project apart.

**Its agents.** Attribute carefully — closing another task's agent destroys
that task. In order of preference:

1. Agents you spawned yourself this session, whose `process_id` you already
   know.
2. Agents whose `list_processes` name starts with the slug (the naming
   convention from the session hook).
3. The `Agents` section of an existing start-here scratchpad, if this session
   was resumed from one.

If any running agent can't be attributed either way, **list it and ask** — never
close an agent you can't account for.

**Its processes.** Any Solo process this work spawned (a watcher, a one-off
server) closes alongside its agents. Shared project services — the dev server,
queue workers, anything predating this work — stay running: other bodies of
work in this project depend on them. Record them in the scratchpad instead.

## 3. Collect handoffs from the agents

For each idle sub-agent, `send_input`:

> Suspending this work. Reply with a concise handoff: what you were asked to
> do, what you actually completed, what's left, files you touched, and any
> gotchas or dead ends worth knowing. No preamble.

Then `timer_fire_when_idle_all` on those process ids with a sensible
`max_wait_ms` (2 minutes is plenty) and a body telling you to collect the
replies. When it fires, `get_process_output` on each and fold the handoffs into
the scratchpad. If one never answered, record that and what it was last asked.

## 4. Write the start-here scratchpad

Find the existing one before creating a new one:

1. If this session was resumed from a start-here scratchpad, use that id.
2. Otherwise `scratchpad_list` with `tags: ["start-here", "<slug>"]`.
3. Only create a new one if neither turns anything up.

Name it `Start Here: <Title>`, tagged `start-here` and the slug. To update,
`scratchpad_read` for the current revision first, then `scratchpad_write` with
`expected_revision` — rewrite the whole document rather than appending, so it
reflects where things stand now rather than accreting stale layers. Keep prior
detail that's still true.

Write it for a session with **no memory of any of this**. Prefer specifics —
paths, commands, PR numbers — over summary.

```markdown
# Start Here: <Title>

**Goal** — one or two sentences on what this work is trying to achieve.

## Where things stand
Current state in a short paragraph. What's working, what isn't.

## Workspace
- Repo / working directory
- Branch, worktree path
- Sandbox URL, PR link
- Uncommitted changes: output of `git status --short`, or "clean"
- Shared processes left running (dev server, watchers) and their Solo names

## Done so far
## Next steps
Ordered and concrete enough to act on without asking questions.

## Key files
Paths plus one line each on why they matter.

## Decisions & why
Choices already made and the reasoning, so they don't get relitigated.

## Dead ends
Approaches already tried that didn't work, and why. Saves repeating them.

## How to verify
Exact test / lint / build commands for this work.

## Agents
Each sub-agent: Solo name, the tool it ran on, its brief, and its handoff.
Recorded so a resumed session can re-spawn equivalents and knows which
processes belonged to this work.

## Related scratchpads
Everything tagged `<slug>`, by name and id.

## Open questions for Jason

---
Last suspended: <YYYY-MM-DD>
```

Never commit or stash on Jason's behalf — record the state of the working tree
and let him decide.

## 5. Update the manifest

One manifest per Solo project: name `Suspended Work`, tag `manifest`. Find it
with `scratchpad_list` (tag `manifest`); create it on first run with this
skeleton:

```markdown
# Suspended Work

Bodies of work that have been suspended, newest first. Each links to a
"start here" scratchpad with enough context to pick it back up.

| Work | Status | Branch / worktree | Updated | Next step |
| --- | --- | --- | --- | --- |
```

Upsert this work's row — one line, `Next step` being the single most useful
thing to do next:

```
| <Title> (scratchpad #<id>) | suspended | <branch> | <YYYY-MM-DD> | <next step> |
```

If a row for this slug already exists (status `active`, from `/resume-work`),
update it in place rather than adding a second. Rows leave the manifest only
via `/finish-work`.

## 6. Close the agents

Only now, and only the agents and processes attributed in section 2:

```
close_process(process_id: <id>)
```

Never pass `confirm_self_close` — this session stays up so Jason can read what
was written.

## 7. Report

Concisely: the scratchpad written (name + id), the manifest row, which agents
were closed, what was deliberately left running and why, and any uncommitted
changes he should deal with.
