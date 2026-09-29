# Master pad Notes

The script owns the pad's `## In-progress reviews` table and rewrites it on every `board` run — never edit the table by hand. It also stamps `Last reconciled` (`reconcile --apply`) and `Last refreshed` (`board --mark-refreshed`). Everything else in the pad is yours: the short preamble and the `## Notes` section.

## Notes section

**Short — a handful of bullets, never more than about six**. Only facts **specific to this repo** that are **still true**:

- the detected repo and project id
- base branches other than the default, and which PRs target them
- drafts that are tracked, and PRs excluded from sweeps (`sweep-plan --exclude` reads these from you)
- model-router calibration for this repo — PRs where `jev-review-model` picked wrong, and what the diff looked like
- `Last reconciled: <date>` and `Last refreshed: <date>`

**Route a lesson before writing it:**

- **True in any repo?** It belongs in the skill — edit the skill file or the script. Mechanism behaviour (truncation, timer reliability, tool quirks) is always this.
- **Specific to this repo?** Notes.
- **Prose that helps a human reading the pad in the Solo UI?** The pad's preamble, a line or two at most.

Appending to the pad because it's already open, when the lesson is really a skill rule, is how Notes grows into a shadow skill — and the pad's copy silently wins, because a session reads the pad first.

**No history.** No "Merge cleanup <date>: #NNNN merged → row removed…", no per-reconcile summaries, no verdict-churn narratives, no batch post-mortems, no list of live agents. The merged PR is in GitHub, the review is in its archived pad, the current state is in the table. Report what changed to the user in chat. Delete accumulated history bullets when you find them.

Edit Notes with one `scratchpad_edit` on the `Notes` section; read it first with `scratchpad_read(mode="section", section_heading="Notes")`.
