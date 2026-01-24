alias tl="tmux list-sessions"
alias ts="tmux new-session -s"
alias ta="tmux attach -t"
alias tksv="tmux kill-server"
alias tks="tmux kill-session"
alias tc="sesh connect"

# Open or create new session via fuzzy finder, or pass z style arg
t() {
  if [ -n "$1" ]; then
    sesh connect $(sesh list -c | grep $1 || echo $1)
    return
  fi

  sesh connect "$(sesh list -i | gum filter --limit 1 --placeholder 'Pick a sesh' --prompt='⚡')"
}