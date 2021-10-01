alias gs='git status -s | grep -q . && echo "$(git status -s)" || echo "Clean as a whistle"'
alias gss='git status'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gc='git commit -m'
alias gcod='gco $(gdb)'
alias gap="git add -p"
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpsh='git push'
alias gnb='git checkout -b'
alias nah='git reset --hard; git clean -df;'
alias glt='git describe --tags --abbrev=0'
alias gt='gittower .'
alias gdb='git remote show origin | grep "HEAD branch" | cut -d " " -f5'
alias gdbardpl='gdbard && gpl'
alias gpr='gh pr checkout'
alias wip="git add . && git commit -m 'wip'"
alias wipa="git add . && git commit --amend -m 'wip'"
alias cdr='cd $(git rev-parse --show-toplevel)'
alias bisect='git bisect'

# Git checkout with fzf
gco() {
  if [ -n "$1" ]; then git checkout $1; return; fi
  local branches branch tags
  branches=$(git branch -vv)
  tags=$(git tag)
  branch=$(echo "$branches $tags" | fzf +m)
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# Switches to the default branch and deletes the branch it was just on.
# gdbard = "Git Delete Branch And Return to Default"
function gdbard {
    branch=$(git branch --show-current)
    default_branch=$(gdb)
    git checkout $default_branch
    git branch -D $branch
}
