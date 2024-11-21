alias gs='git status -s | grep -q . && echo "$(git status -s)" || echo "Clean as a whistle"'
alias gss='git status'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glf="gl --no-merges --first-parent;" # git log flat
alias gc='git commit -m'
alias gco='git checkout'
alias gcod='gco $(gdb)'
alias gap="git add -p"
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpsh='git push'
alias gst='git stash -u'
alias gpop='git stash pop'
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
  gh_pretty_list_prs | gum filter --placeholder 'Checkout PR...' | awk '{print $1}' | sed "s/#//" | xargs gh pr checkout
}
gh_pretty_list_prs() {
  gh pr list \
    --limit 500 \
    --json number,title,author,headRefName,updatedAt \
    --template '{{range .}}{{tablerow (printf "#%v" .number | autocolor "green") (truncate 60 .title) (truncate 15 .author.login) (truncate 40 .headRefName) (timeago .updatedAt)}}{{end}}'
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

# Git checkout recent with fzf
gcor() {
    local branches branch
    branches=$(git reflog show --pretty=format:'%gs ~ %gd' --date=relative | grep checkout | grep -oE '[^ ]+ ~ .*' | awk -F~ '!seen[$1]++' | head -n 20 | awk -F' ~ HEAD@{' '{printf("%s: %s\n", substr($2, 1, length($2)-1), $1)}')
    selection=$(echo "$branches" | gum filter)
    branch=$(echo "$selection" | awk '{print $NF}')
    git checkout $branch
}

gbd() {
  if [ -n "$1" ]; then git branch -d $1; return; fi
  local branches branch selected
  branches=$(git branch -vv) &&
  selected=$(echo "$branches" | gum filter | awk '{print $1}' | sed "s/.* //")
  gum confirm "Are you sure you would like to delete branch [$selected]?" \
    --default=false --affirmative "Yes, Delete it." --negative "Nevermind." \
    && git branch -d $selected || echo "Aborted."
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
