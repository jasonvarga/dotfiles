alias c='clear'
alias o='open .'
alias l="eza --icons --group-directories-first -1"
alias ll="eza -alF"
alias lg="l --grid"
alias llg="ll --grid"
alias rm="trash"
alias sizes='du -sh -c *'
alias weather='curl -s wttr.in | sed -n "1,7p"'
alias dot='cd ~/.dotfiles'
alias iterm='open . -a iterm'
alias bs='brew services'
alias sbs='sudo brew services'
alias pstorm='open -a "PhpStorm"'
eval $(thefuck --alias)

# Copy pwd to clipboard without trailing newline
alias cwd="pwd && pwd | tr -d '\n' | pbcopy && echo 'Copied to clipboard 📁'"

# Open vscode with z argument
zode() {
  if [ -n "$1" ]; then
    z $1
  fi
  code .
}

# Open sublime with z argument
zubl() {
  if [ -n "$1" ]; then
    z $1
  fi
  subl .
}

# Make directory and cd into it
mkcdir ()
{
    mkdir -p -- "$1" &&
       cd -P -- "$1"
}

internet() {
    disconnected=false

    while ! ping 8.8.8.8 -c 1 &> /dev/null; do
        echo '❌ No internet connection.'
        disconnected=true
        sleep 1;
    done;

    # Show notification only if it was ever disconnected, so you
    # can leave the command running in the background.
    if $disconnected; then
        osascript -e 'display notification "Connection restored ✅" with title "Internet"'
    fi

    echo '✅ Connected to internet.'
}
