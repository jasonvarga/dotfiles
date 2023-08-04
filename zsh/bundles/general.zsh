alias c='clear'
alias o='open .'
alias ls="ls -aFG"
alias l="ls"
alias ll="ls -l"
alias rm="trash"
alias sizes='du -sh -c *'
alias weather='curl -s wttr.in | sed -n "1,7p"'
alias dot='cd ~/.dotfiles'
alias iterm='open . -a iterm'
alias bs='brew services'
alias sbs='sudo brew services'
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
