# Refresh sweep

A review goes stale when the PR moves under it. This sweep finds every tracked PR that has moved since it was reviewed and brings those reviews up to date — so the user never has to notice a push themselves, or tell an individual agent "commits were pushed".

**Two kinds of movement, both count:**

- **New commits** — the code changed; the review must be redone against the new diff.
- **New discussion** — same code, but somebody said something. A contributor explaining *why*, a maintainer clarifying intended behaviour, a user reporting the branch does or doesn't fix their case, an answer to a question the review raised — any of it can resolve a finding, invalidate one, or surface one the diff alone doesn't show. **Comments are not noise.** A review written without context that has since been posted is out of date in exactly the way this sweep exists to fix.

They differ only in the size of the job — commits means re-read the diff, comments means read and reconsider — and both go through the same pipeline.

If the user names specific PRs ("refresh 15182 and 15192"), sweep only those.

## 1. Every open PR's head commit, in one call

```bash
gh pr list --repo <OWNER/REPO> --state open --limit 300 --json number,headRefOid,updatedAt
```

Covers the whole board. Do **not** loop `gh pr view` per PR.

## 2. Narrow to the PRs that actually moved

Each review pad's first line records what that review took in:

```
Reviewed at commit: <short sha> · discussion through: <ISO8601 timestamp>
```

Read those cheaply — `scratchpad_read(..., mode="content", limit=1)` per pad, or `scratchpad_list(project_id=..., tags=["review"])` first and only read the pads for PRs that look changed.

- **Recorded sha ≠ current `headRefOid`** → **commits**. (Comments it also picked up come along for free.)
- **Sha matches, `updatedAt` newer than the recorded timestamp** → candidate for **discussion**. Confirm real human discussion before waking anyone:
  ```bash
  gh pr view <number> --repo <OWNER/REPO> --json comments,reviews
  ```
  Count only items newer than the recorded timestamp, and only from humans. Skip bot authors (login ending `[bot]`), pure label/milestone/base churn (bumps `updatedAt` with no comment at all), and any of your own reviews posted back to the PR — re-reviewing because of your own posted review is circular. Nothing survives the filter → skip silently.
- **Sha matches, no newer discussion** → up to date. Skip. No agent woken.
- **No `Reviewed at commit:` line** (pads predating the convention) → fall back to timestamps. If the PR's `updatedAt` is newer than the pad's `updated_at`:
  ```bash
  gh pr view <number> --repo <OWNER/REPO> --json commits,comments,reviews
  ```
  Last commit's `committedDate` newer than the pad → commits. Else human comments newer than the pad → discussion. Neither → skip.

A merged/closed PR shows up as simply missing from the open list — run merge cleanup for those as part of the sweep.

## 3. Report before acting

Three short lists, PR numbers only: **new commits**, **new discussion**, **merged/closed**.

If the two action lists together come to **more than 10 PRs**, stop and ask which to do before spawning. Below that, proceed straight to step 4 without asking — that's the whole point of the sweep.

## 4. Bring each up to date, five at a time

Work in **batches of five**: spawn or nudge five, arm an idle-watch timer over them, harvest when it fires, then start the next five. A big fan-out competes for the same machine, and a failure in one is easy to lose among twenty.

Set the `⏳` icons for the **whole** action list up front in one `section` edit, not per batch — the board then shows what the sweep will touch, and each harvest is a small line edit.

For each PR in the batch:

- **Agent still running** (resolve it per the skill's agent registry) → nudge it. Wording: `references/review-task.md`.
- **No agent running** → spawn a fresh one (skill's spawn steps for naming and model) and send the standard task plus the "reviewed before" line from `references/review-task.md`.

## 5. Harvest, close, repeat

Arm the idle-watch timer and harvest exactly as the skill describes — verifying each pad advanced before trusting it.

**Close each agent the sweep spawned once its verdict is harvested.** A sweep agent is a throwaway that exists to refresh one pad; fifteen idle ones clutter the process list for nothing, and the user can always respawn a discussion agent against the written review. `kv_delete` the ones you close.

**Agents already running before the sweep are left alone** — those are ones the user is actively working with. Nudging them is fine; closing them is not. Snapshot `kv_list(prefix="agent.pr-")` before the sweep so you can tell which were pre-existing.

When the whole action list is done: set `Last refreshed` in Notes to today's date, and confirm no `⏳` rows remain. Report only state — which PRs were re-reviewed and which icons changed, never what changed in them.
