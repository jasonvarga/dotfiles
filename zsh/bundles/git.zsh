alias gs='git status -s | grep -q . && echo "$(git status -s)" || echo "Clean as a whistle"'
alias gss='git status'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gc='git commit -m'
alias gco='git checkout'
alias gcod='gco $(gdb)'
alias gap="git add -p"
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpsh='git push'
alias gnb='git checkout -b'
alias nah='git reset --hard; git clean -df;'
alias glt='git describe --tags --abbrev=0' # git latest tag
alias gcslt='git --no-pager log $(glt)..HEAD --oneline --no-decorate --first-parent --no-merges' # git commits since latest tag
alias gin="git init && git add . && gc 'Initial commit.'"
alias gpub='git push --set-upstream origin HEAD'
alias gt='gittower .'
alias gdb='git remote show origin | grep "HEAD branch" | cut -d " " -f5'
alias gpro='gh pr view --web'
alias wip="git add . && git commit -m 'wip'"
alias wipa="git add . && git commit --amend -m 'wip'"
alias cdr='cd $(git rev-parse --show-toplevel)'
alias bisect='git bisect'

# Git checkout PR
gpr() {
  if [ -n "$1" ]; then gh pr checkout $1; return; fi
  pr=$(gh pr list --limit=100 | fzf +m | awk '{print $1}')
  echo "Checking out PR #$pr..."
  gh pr checkout $(echo "$pr")
}

# Git checkout with fzf
gcob() {
  if [ -n "$1" ]; then git checkout $1; return; fi
  local branches branch
  branches=$(git branch -vv)
  branch=$(echo "$branches" | fzf +m)
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# Git checkout tag with fzf
gcot() {
  if [ -n "$1" ]; then git checkout $1; return; fi
  local tag tags
  tags=$(git tag)
  tag=$(echo "$tags" | fzf +m)
  git checkout $(echo "$tag" | awk '{print $1}' | sed "s/.* //")
}

gbd() {
  if [ -n "$1" ]; then git branch -d $1; return; fi
  local branches branch selected
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  selected=$(echo "$branch" | awk '{print $1}' | sed "s/.* //")
  echo "Are you sure you would like to delete branch [$selected]? (Type 'delete' to confirm)"
  read confirmation
  if [[ "$confirmation" == "delete" ]]; then
    git branch -D $selected
  else
    echo "Aborted"
  fi
}

# Switches to the default branch and deletes the branch it was just on.
# gdbard = "Git Delete Branch And Return to Default"
function gdbard {
    branch=$(git branch --show-current)
    default_branch=$(gdb)
    git checkout $default_branch
    git branch -D $branch
    git pull
}

# Switches to the master branch and deletes the branch it was just on.
# gdbarm = "Git Delete Branch And Return to Master"
function gdbarm {
    branch=$(git branch --show-current)
    git checkout master
    git branch -D $branch
    git pull
}

# Check if a branch exists on the remote
# grbe = "Git Remote Branch Exists"
function grbe {
    if [ -n "$1" ]; then
        branch=$1
    else
        branch=$(git branch --show-current)
    fi
    exists=$(git ls-remote --exit-code --heads origin $branch)
    code=$?
    if [[ -n $exists ]]; then echo "Exists"; else echo "Does not exist"; fi
    return $code
}

function gcolt() {
    tag=$(glt)
    echo "Checking out $tag"
    gco $tag
}
