zstyle ':autocomplete:*' widget-style menu-select
zstyle ':autocomplete:*' fzf-completion yes
zstyle ':autocomplete:*' list-lines 5
zstyle ':autocomplete:*' min-delay 0.2
zstyle ':autocomplete:*' min-input 1

zle -N up-line-or-search
up-line-or-search() {
  if [[ $LBUFFER == *$'\n'* ]] then
    zle up-line
  else
    fzf-history-widget
  fi
}
