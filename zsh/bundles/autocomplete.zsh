zstyle ':autocomplete:*' widget-style menu-select
zstyle ':autocomplete:*' fzf-completion yes
zstyle ':autocomplete:*' list-lines 10
zstyle ':autocomplete:*' min-delay 0.2
zstyle ':autocomplete:*' min-input 1

# Make left/right arrow keys move the cursor in the menu.
# Without this, they would also go up/down the options.
bindkey -M menuselect  '^[[D' .backward-char  '^[OD' .backward-char
bindkey -M menuselect  '^[[C'  .forward-char  '^[OC'  .forward-char