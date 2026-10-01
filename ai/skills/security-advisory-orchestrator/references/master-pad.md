# Master pad Notes

The script owns the pad's `## Open advisories` table and rewrites it on every `board` run — never edit the table by hand. It also stamps `Last reconciled` (`reconcile --apply`). Everything else in the pad is yours: the short preamble and the `## Notes` section.

## Notes section

**Short — a handful of bullets, never more than about six**. Only facts **specific to this repo** that are **still true**:

- the detected repo and project id
- affected-version conventions or branch policy specific to this repo
- any advisory deliberately parked, and why
- `Last reconciled: <date>`

**Route a lesson before writing it:**

- **True in any repo?** It belongs in the skill — edit the skill file or the script. Mechanism behaviour (truncation, timer reliability, tool quirks) is always this.
- **Specific to this repo?** Notes.
- **Prose that helps a human reading the pad in the Solo UI?** The pad's preamble, a line or two at most.

Appending to the pad because it's already open, when the lesson is really a skill rule, is how Notes grows into a shadow skill — and the pad's copy silently wins, because a session reads the pad first.

**No history.** No "Cleanup <date>: GHSA-xxxx published → row removed…", no per-reconcile summaries, no batch post-mortems, no list of live agents. The published advisory is on GitHub, the analysis is in its archived pad, the current state is in the table. Report what changed to the user in chat. Delete accumulated history bullets when you find them.

**Never put vulnerability detail in Notes.** No exploit paths, no affected-code pointers, no severity reasoning. That belongs in the advisory's own pad, which gets archived when the advisory closes; the master pad is long-lived and read at the start of every session.

Edit Notes with one `scratchpad_edit` on the `Notes` section; read it first with `scratchpad_read(mode="section", section_heading="Notes")`.
