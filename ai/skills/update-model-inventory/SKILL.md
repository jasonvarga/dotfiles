---
name: update-model-inventory
description: Refresh ai/models.json from the models currently selectable in Jason's Claude and Codex subscriptions. Use when asked to update, refresh, or audit the model inventory; do not use to recommend a model for a task.
---

# Update model inventory

Keep `ai/models.json` an accurate, hand-readable inventory for the `model-selection` skill. Its entries come from model *choices available in the interactive Claude and Codex clients*, not API model catalogs. Apply the Codex preference below when choosing which available models to include.

## Discover the current choices

Use Solo MCP as the primary evidence source. It sees the locally authenticated clients and avoids guessing from vendor documentation.

1. Call `mcp__solo__list_projects` and find the project whose path is the current dotfiles repository. Call `mcp__solo__list_agent_tools` and resolve the enabled `Claude` and `Codex` runtimes by their returned IDs.
2. Spawn one fresh agent for each runtime in that project, named `model-inventory: claude` and `model-inventory: codex`. Do not add `--model` arguments: the default picker is what is being audited.
3. Send each process `/model`, then inspect its output with `mcp__solo__get_process_output`. If the picker needs a follow-up to render, send only the minimal input needed to display its choices. Never select or change a model.
4. Capture the exact selectable model names and reasoning-effort settings for each model. Treat the picker as authoritative for model availability. For Codex, if the picker does not expose every effort setting, read `~/.codex/models_cache.json`. Check its `fetched_at` value, match each picker model name to `models[].slug`, and take the effort strings in order from `models[].supported_reasoning_levels[].effort`. Do not use cached models that are absent from the picker. For Claude, use the effort choices shown by its picker; if it does not reveal the full list, report the gap rather than assuming the Codex cache applies. Do not infer availability, aliases, effort levels, context limits, pricing, or descriptions from stale inventory entries or marketing pages.
5. After collecting the inventories, close each probe agent with `mcp__solo__close_process`. Close failed probes too, including when only one surface fails. If discovery fails for one surface, retain that surface's existing entries unchanged and report the failed probe; never remove models merely because a probe was unavailable.

If Solo is unavailable, ask the user to run `/model` in each client and provide the displayed options. Do not browse as a substitute: web documentation does not reliably match the user's subscription or client rollout.

## Update the file

Edit only `ai/models.json` unless the user explicitly requests related changes.

- Preserve the JSON array schema consumed by `ai/jev/bin/jev-model-selection`: every entry needs unique `id`, `platform`, `model`, `surface`, `description`, and `effort`. Set `effort` to the array of selectable reasoning-effort strings in client order. Use an empty array only when the client confirms that the model has no selectable effort setting. If settings cannot be determined, retain an existing model's effort values or defer adding a new model, and report the gap instead of guessing.
- Use `platform: "OpenAI"` / `surface: "Codex"` for Codex choices and `platform: "Anthropic"` / `surface: "Claude"` for Claude choices.
- For Codex, include current models offered by the picker and exclude choices it describes as "older" or "legacy", even if they remain selectable. Use the picker's current labels on each run so new current models can be added and newly older models can be removed.
- Use stable, lowercase, hyphenated IDs in the form `<platform>-<model>`, retaining meaningful version and context qualifiers. Resolve collisions deterministically rather than creating duplicates.
- Preserve a model's existing description when its identity still matches. For a newly found model, write a short, neutral description based only on information shown by the picker; if the picker provides no useful characterization, use `"Selectable in <surface>."`.
- Keep the order grouped by surface: Codex first, then Claude. Within a surface, follow the picker order when it is clear; otherwise preserve prior relative order and append new choices.
- Remove an entry when its own successful picker no longer offers it, or when the Codex picker describes it as "older" or "legacy". A picker that is incomplete or ambiguous is not evidence for removal of an otherwise eligible entry.

## Verify and report

Run `jq empty ai/models.json` and verify that every entry has an `effort` array. Validate it with the existing router by piping a short test task to `ai/jev/bin/jev-model-selection`. Confirm that the Codex entries match the current choices after excluding those labeled "older" or "legacy". Review the diff for accidental changes outside the inventory and any explicitly requested related files. Report added, removed, and materially changed entries, along with any uncertainty or failed probe.
