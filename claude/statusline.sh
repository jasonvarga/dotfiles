#!/bin/bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | xargs printf '%.0f')

prompt=$(starship prompt --path "$cwd" \
    | sed 's/%{//g; s/%}//g' `# strip zsh prompt escape sequences` \
    | sed '$ d') `# remove prompt line`

GRAY=$'\e[90m'
RESET=$'\e[0m'

echo "$prompt ${GRAY}(${context_used}%)${RESET}"