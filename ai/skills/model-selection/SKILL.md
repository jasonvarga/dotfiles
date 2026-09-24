---
name: model-selection
description: Recommend the best available ChatGPT/Codex or Claude model and reasoning setting for a described task. Use when choosing a model, effort level, or platform; do not use when the user has already selected one.
---

# Model Selection

Recommend a model and effort setting across the user's ChatGPT/Codex and Claude subscriptions. The execution environment is not evidence that its own models are preferable: Claude may be the best choice when it fits the work better, and vice versa.

## Understand the work

When the user names a skill, codebase, pull request, document, or other artifact, inspect the relevant source before making a recommendation. Never route from its name alone. Read the artifact's entrypoint and only the supporting files needed to understand its actual work. For a skill, start with its `SKILL.md` and follow its explicitly relevant references.

When the user instead gives a raw description of a job with nothing to inspect, use that description directly as the basis for the brief below.

## Build the router brief

Distill the work—inspected artifact or raw description alike—into a compact router brief covering these fields. Score each against the anchors below—verbatim where they fit—so the brief reads the same regardless of which model is writing it:

- **Outcome**: one sentence, what the work produces.
- **Primary work type**: name it concretely (e.g. procedural CLI orchestration, code review, debugging, design, creative writing, data extraction).
- **Tool/file access needed**: the concrete tools/APIs actually invoked, not capabilities in the abstract.
- **Reasoning difficulty**: low = deterministic/procedural, an explicit checklist with little judgment; moderate = bounded judgment calls inside an otherwise scripted process (e.g. picking a category, wording a summary); high = open-ended design, debugging with unknown root cause, or reconciling conflicting requirements.
- **State/concurrency**: none = single linear pass; sequential = ordered steps/phases, nothing waited on; concurrent = coordinates parallel/background actors or waits on external events.
- **Context size**: small = a few files or command outputs; medium = a full module or moderate diff; large = a whole codebase or many long documents.
- **Risk of error**: low = mistakes are easily caught or reversible; moderate = guarded by explicit stop conditions before anything destructive; high = irreversible or externally-visible action with no guard.
- **Latency/cost sensitivity**: low = interactive but infrequent; high = runs at volume or blocks a human waiting live.

Send that brief—not a large raw artifact or the user's full message—to Jev. If a named artifact can't be accessed, or the user's raw description is too thin to score these fields, state that and route only the information actually available.

## Route with Jev

Run the router with the brief. It loads the canonical candidate inventory and maps Jev's reasoning-demand score to the chosen model's exact selectable effort setting:

```sh
printf '%s' "$router_brief" | jev-model-selection
```

Use the router's selected model and effort unchanged. Turn its signals into a concise task-specific rationale. Do not read or modify `ai/models.json`; the router owns it. If the router fails, say so and make a clearly labeled best-effort recommendation from the user's stated options.

## Response format

Give a decisive answer first, then a compact rationale:

```
Recommendation: **<surface> <model>, <exact selectable effort setting> effort** (e.g. "Codex gpt-5.6-sol, medium effort")

Why: <one or two task-specific reasons>
```

Mention uncertainty only when it changes the decision. Honor an explicit user preference for a platform unless it makes the task infeasible; then flag the constraint and offer the closest viable option.

For high-stakes decisions, separate the recommendation from the required verification or human review. Model selection does not make the output authoritative.
