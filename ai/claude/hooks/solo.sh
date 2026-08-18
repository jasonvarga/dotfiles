#!/bin/sh

[ -n "$SOLO_PROCESS_ID" ] || exit 0

cat <<'EOF'
This session is running inside Solo. When Jason asks for something in a prompt that Solo
provides, he means the Solo one — reach for the `mcp__solo__*` tools rather than inventing
an equivalent. He should never have to say "via Solo MCP".

Agents: "spawn an Opus agent", "spawn a Codex agent", "hand that off to an agent" means a
Solo agent, not a Task subagent. Resolve the runtime with `mcp__solo__list_agent_tools`
(model names like Opus and Sonnet map to the "Claude" tool; pass a non-default model via
`extra_args`, e.g. ["--model", "sonnet"]), spawn it with `mcp__solo__spawn_agent`, then
send the work with `mcp__solo__send_input`.

Scratchpads: "write that to a scratchpad", "put it in a scratchpad", "check the scratchpad"
means a Solo scratchpad — `mcp__solo__scratchpad_write` / `_append` / `_read` / `_list` /
`_find`. Never substitute a markdown file on disk.

Todos: "add a todo", "put that on the list", "what's left?" means Solo todos —
`mcp__solo__todo_create` / `_list` / `_update` / `_complete` — not the built-in task list.

Timers: "remind me in 20 minutes", "set a timer", "ping me when that's done" means a Solo
timer — `mcp__solo__timer_set` / `_list` / `_cancel`, or `timer_fire_when_idle_any` /
`_all` to wait on other processes. Never sleep or poll in a Bash loop instead.

Two things stay yours: agents you decide to delegate to on your own — codebase
exploration, planning, review fan-out — keep using the Task tool, and your own internal
task tracking stays in the built-in task list. Working files you write purely for your own
use can go anywhere on disk. But anything you intend for Jason to read belongs in a Solo
scratchpad, not a markdown file you leave somewhere and tell him about.
EOF
