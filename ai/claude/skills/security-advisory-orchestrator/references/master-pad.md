# Master scratchpad format

Title, exactly: `Security Advisory Orchestrator — Master Status Table`. Tags: `["index", "orchestrator", "security", "advisory"]`.

## The table

One table, newest first:

```markdown
## Open advisories

|  | ID | Source | Summary |
|--|----|--------|---------|
| <icon> | [GHSA-xxxx-xxxx-xxxx](solo://proj/<PROJECT_ID>/scratchpad/<slug>--<id>) | GHSA | Short summary |
```

**The ID links to the advisory scratchpad, not to GitHub.** There is no Scratchpad column. GitHub `https://` links don't open from the Solo UI at all, and the pad is what gets opened far more often than the GHSA page — so the one link per row goes to the thing that works and gets used. The id stays the visible label; it's copy-pasteable as text when you do need GitHub. Until an agent has published its pad, leave the cell as plain unlinked text and link it at harvest.

Take the `solo://` URL from the `url` field returned by `scratchpad_read` / `scratchpad_write`. Never hand-build the slug — it's a truncated kebab of the title and easy to get wrong. Use clickable solo links in status output to the user too, not bare ids.

**ID column**: the GHSA identifier for GitHub-sourced advisories; a local `ADV-YYYY-NN` slug for pasted and file submissions, incrementing the counter in Notes.

**Newest first.** New rows go at the **top**. GHSA ids don't sort meaningfully, so this is insertion order, not an alphabetical sort — the advisory being worked on shouldn't sit below a long tail of older ones.

**Summary goes last.** It's the only variable-width column, so trailing it keeps the icon and link at a stable left-hand position, clickable without horizontal scrolling. A summary running off the right edge is fine; scrolling to reach a *link* is not.

**Keep the icon and the link in separate cells.** Do not inline them as `<icon> [GHSA-…](...)` — the Solo UI's markdown reformatter strips a link sharing a cell with an emoji. A link alone in its cell survives.

**Summary cells hold the summary and nothing else.** Never append the severity, the CVSS vector, a blocking question, or a caveat — not in parentheses, not after a dash. The icon carries the status; the linked pad carries everything else.

**No agent column.** Solo agent processes aren't deep-linkable, so an id in a cell isn't clickable or useful. Agents are named `<short-id> - <short description>` and their ids live in KV. Don't keep a live-agents list in Notes either — a hand-maintained liveness list can't observe a process dying, goes stale silently, and costs an edit on every spawn and cleanup.

Every row is an open, in-flight advisory. Published, withdrawn or closed out → the row is **removed** and its pad archived. No history, no published column.

## Editing a single row

`scratchpad_edit` with a `line_range` target is the cheap way to flip one icon without rewriting the table. But **`offset` counts lines from the top of the document, not the top of the table** — prose, legend and heading all come first, so table-relative offsets overwrite whatever prose sits at that line.

Read the target line first, every time:

```
scratchpad_read(scratchpad_id=<id>, mode="content", offset=N, limit=1)   # confirm
scratchpad_edit(scratchpad_id=<id>, expected_revision=<rev>,
                target={"type":"line_range","offset":N,"limit":1},
                content="| 📝 | [GHSA-xxxx-xxxx-xxxx](...) | GHSA | Short summary |")
```

Offsets shift whenever a row is added or removed, so a number that was right earlier in the session may be stale. Re-confirm rather than reusing it. Changing many rows at once: one `section` edit of `Open advisories` beats a run of line edits.

## Notes section

At the bottom, **short — a handful of bullets, never more than about six**. Only facts **specific to this repo** that are **still true**:

- the detected repo and project id
- `Local ID counter: ADV-2026-03` — the last locally-assigned id
- affected-version conventions or branch policy specific to this repo
- any advisory deliberately parked, and why
- `Last reconciled: <date>`

**Route a lesson before writing it:**

- **True in any repo?** It belongs in the skill — edit the skill file. Mechanism behaviour (truncation, timer reliability, tool quirks) is always this.
- **Specific to this repo?** Notes.
- **Prose that helps a human reading the pad in the Solo UI?** The pad's preamble, a line or two at most.

Appending to the pad because it's already open, when the lesson is really a skill rule, is how Notes grows into a shadow skill — and the pad's copy silently wins, because a session reads the pad first.

**No history.** No "Cleanup <date>: GHSA-xxxx published → row removed…", no per-reconcile summaries, no batch post-mortems. That log is write-only noise that grows without bound and burns context on every read: the published advisory is on GitHub, the analysis is in its archived pad, the current state is in the table. Report what changed to the user in chat. Delete accumulated history bullets when you find them.

**Never put vulnerability detail in Notes.** No exploit paths, no affected-code pointers, no severity reasoning. That belongs in the advisory's own pad, which gets archived when the advisory closes; the master pad is long-lived and read at the start of every session.
