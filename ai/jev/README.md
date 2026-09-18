# Jev scripts

Small commands built on [TypeSafe's](https://docs.typesafe.ai) Jev model, which
answers typed questions about text — a probability, a label, or a score — rather
than generating prose. Skills and shell usage call these directly.

`bin` is on `PATH` (see `zsh/zshrc`), so each script is a bare command.

| Command | What it does |
| --- | --- |
| `jev-review-model` | Reads a PR diff on stdin, prints `opus` / `sonnet` / `either` for which model should review it. `--json` for structured output. |

They need `TYPESAFE_API_KEY` in the environment; it lives in
`zsh/bundles/private.zsh` (untracked).

Dependencies install once for all scripts — `npm --prefix ~/.dotfiles/ai/jev install`.
The dotbot run does this.

## Adding a script

Drop an executable file in `bin`, no extension, `#!/usr/bin/env node` at the top.
Node treats it as ESM via `"type": "module"` here, and resolves `@typesafe-ai/sdk`
by walking up from `bin`.

Keep the judgments and the policy separate: ask Jev only what needs semantic
understanding, and let the script apply thresholds and do any counting, so the
rules stay visible and tunable without another inference call.
