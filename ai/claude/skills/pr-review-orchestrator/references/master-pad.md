# Master scratchpad format

Title, exactly: `PR Review Orchestrator — Master Status Table`. Tags: `["index", "orchestrator", "pr", "review"]`.

## The table

One review table, newest first:

```markdown
## In-progress reviews

|  | PR | Title |
|--|----|-------|
| <icon> | [#NNNN](solo://proj/<PROJECT_ID>/scratchpad/<slug>--<id>) | Title without branch prefix |
```

**The PR number links to the review scratchpad, not to GitHub.** There is no Scratchpad column. GitHub `https://` links don't open from the Solo UI at all, and the pad is what gets opened far more often than the PR page — so the one link per row goes to the thing that works and gets used. Until an agent has published its pad, leave the cell as plain unlinked `#NNNN` and link it at harvest.

Take the `solo://` URL from the `url` field returned by `scratchpad_read` / `scratchpad_write`. Never hand-build the slug — it's a truncated kebab of the title and easy to get wrong. Use clickable solo links in status output to the user too, not bare ids.

**Sort by PR number descending.** New rows go at the **top**; the newest reviews are the ones being looked at and shouldn't sit below a long tail of old ones.

**Title goes last.** It's the only variable-width column, so trailing it keeps the icon and link at a stable left-hand position, clickable without horizontal scrolling. A title running off the right edge is fine; scrolling to reach a *link* is not.

**Keep the icon and the link in separate cells.** Do not inline them as `<icon> [#NNNN](...)` — the Solo UI's markdown reformatter strips a link sharing a cell with an emoji. A link alone in its cell survives.

**Title cells hold the PR title and nothing else.** Never append a verdict reason, blocking issue, base-branch note, or caveat — not in parentheses, not after a dash. The icon carries the verdict; the linked pad carries the reasoning. If you catch yourself writing `(no tests)` or `— BLOCKED: …` or `(base: forms-2)`, delete it.

**No agent column.** Solo agent processes aren't deep-linkable, so an id in a cell isn't clickable or useful. Agents are named `<pr number> - <short description>` and their ids live in KV. Don't keep a `Live agents` list in Notes either — a hand-maintained liveness list can't observe a process dying, goes stale silently, and costs an edit on every spawn and cleanup.

Every PR in the table is open by definition. Merged or closed → the row is **removed** and its review pad archived. No history, no open/closed column; the useful signal is the verdict icon.

(If a future Solo version exposes a deep link for agent processes, reconsider adding the agent as a clickable column.)

## Editing a single row

`scratchpad_edit` with a `line_range` target is the cheap way to flip one icon without rewriting the table. But **`offset` counts lines from the top of the document, not the top of the table** — prose, legend and heading all come first, so table-relative offsets overwrite whatever prose sits at that line.

Read the target line first, every time:

```
scratchpad_read(scratchpad_id=<id>, mode="content", offset=N, limit=1)   # confirm
scratchpad_edit(scratchpad_id=<id>, expected_revision=<rev>,
                target={"type":"line_range","offset":N,"limit":1},
                content="| ✅ | [#NNNN](...) | Title |")
```

Offsets shift whenever a row is added or removed, so a number that was right earlier in the session may be stale. Re-confirm rather than reusing it. Changing many rows at once: one `section` edit of `In-progress reviews` beats a run of line edits.

## Notes section

At the bottom, **short — a handful of bullets, never more than about six**. Only facts **specific to this repo** that are **still true**:

- the detected repo and project id
- base branches other than the default, and which PRs target them
- drafts that are tracked, and any excluded from sweeps
- model-router calibration for this repo — PRs where `jev-review-model` picked wrong, and what the diff looked like
- `Last reconciled: <date>` and `Last refreshed: <date>`

**Route a lesson before writing it:**

- **True in any repo?** It belongs in the skill — edit the skill file. Mechanism behaviour (truncation, timer reliability, tool quirks) is always this.
- **Specific to this repo?** Notes.
- **Prose that helps a human reading the pad in the Solo UI?** The pad's preamble, a line or two at most.

Appending to the pad because it's already open, when the lesson is really a skill rule, is how Notes grows into a shadow skill — and the pad's copy silently wins, because a session reads the pad first.

**No history.** No "Merge cleanup <date>: #NNNN merged → row removed…", no per-reconcile summaries, no verdict-churn narratives, no batch post-mortems. That log is write-only noise that grows without bound and burns context on every read: the merged PR is in GitHub, the review is in its archived pad, the current state is in the table. Report what changed to the user in chat. Delete accumulated history bullets when you find them.
