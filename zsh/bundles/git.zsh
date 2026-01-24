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
alias gpsh='gpf' # "git push", but also fetches.
alias gst='git stash -u'
alias gpop='git stash pop'
alias gm='git merge'
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
  local pr_number
  if [ -n "$1" ]; then
    pr_number=$1
  else
    pr_number=$(gh_pretty_list_prs | gum filter --placeholder 'Checkout PR...' | awk '{print $1}' | sed "s/#//")
    if [ -z "$pr_number" ]; then return; fi
  fi

  gh pr checkout $pr_number

  local pr_info=$(gh pr view $pr_number --json isCrossRepository,headRepositoryOwner,headRefName,headRepository)
  local is_fork=$(echo $pr_info | jq -r '.isCrossRepository')

  if [ "$is_fork" = "true" ]; then
    local fork_owner=$(echo $pr_info | jq -r '.headRepositoryOwner.login')
    local branch_name=$(echo $pr_info | jq -r '.headRefName')
    local repo_name=$(echo $pr_info | jq -r '.headRepository.name')
    local fork_url="git@github.com:${fork_owner}/${repo_name}.git"

    if git remote get-url $fork_owner &> /dev/null; then
      git remote set-url $fork_owner $fork_url
    else
      git remote add $fork_owner $fork_url
    fi
    git fetch $fork_owner

    git branch --set-upstream-to=$fork_owner/$branch_name
  fi
}
gh_pretty_list_prs() {
  gh pr list \
    --limit 500 \
    --json number,title,author,headRefName,updatedAt \
    --template '{{range .}}{{tablerow (printf "#%v" .number | autocolor "green") (truncate 60 .title) (truncate 15 .author.login) (truncate 40 .headRefName) (timeago .updatedAt)}}{{end}}'
}

# Git fetch tracked - fetches the current branch's remote to update tracking info
gft() {
    local remote=$(git config --get branch.$(git branch --show-current).remote 2>/dev/null)
    if [ -n "$remote" ]; then
        git fetch $remote
    else
        echo "No remote configured for current branch"
        return 1
    fi
}

# Git push and fetch - pushes then fetches to update tracking info
# Useful when pushing to fork remotes to avoid "ahead by X commits" status
gpf() {
    git push "$@" && gft
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
    remote=$(git config --get branch.$branch.remote 2>/dev/null)
    default_branch=$(gdb)
    git checkout $default_branch
    git branch -D $branch
    git pull
    if [ -n "$remote" ] && [ "$remote" != "origin" ]; then
        grclean $remote
    fi
}

# Switches to the master branch and deletes the branch it was just on.
# gdbarm = "Git Delete Branch And Return to Master"
function gdbarm {
    branch=$(git branch --show-current)
    remote=$(git config --get branch.$branch.remote 2>/dev/null)
    git checkout master
    git branch -D $branch
    git pull
    if [ -n "$remote" ] && [ "$remote" != "origin" ]; then
        grclean $remote
    fi
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

# Git Remote List - lists all non-origin remotes and their tracking branches
function grlist() {
    local remotes=$(git remote | grep -v "^origin$")

    if [ -z "$remotes" ]; then
        echo "No non-origin remotes found"
        return
    fi

    echo "$remotes" | while read -r remote; do
        local url=$(git remote get-url "$remote" 2>/dev/null)
        echo ""
        echo "$remote ($url):"
        local branches=$(git branch -vv | grep "\[$remote/")
        if [ -n "$branches" ]; then
            echo "$branches" | sed 's/^/  /'
        else
            echo "  (no tracking branches)"
        fi
    done
}

# Git Remote Cleanup - removes fork remotes that are no longer used by any branch
# Usage: grclean [remote_name]
#   - With remote_name: removes that specific remote if no branches use it
#   - Without args: removes all unused remotes except origin
function grclean() {
    if [ -n "$1" ]; then
        local remote=$1

        if [ "$remote" = "origin" ]; then
            echo "Cannot delete origin remote"
            return 1
        fi

        if ! git remote | grep -q "^${remote}$"; then
            echo "Remote '$remote' does not exist"
            return 1
        fi

        if git branch -vv | grep -q "\[$remote/"; then
            echo "Remote '$remote' is still used by other branches"
            git branch -vv | grep "\[$remote/"
            return 1
        fi

        echo "Removing unused remote: $remote"
        git remote remove $remote
    else
        local removed=0
        for remote in $(git remote | grep -v "^origin$"); do
            if ! git branch -vv | grep -q "\[$remote/"; then
                echo "Removing unused remote: $remote"
                git remote remove $remote
                ((removed++))
            fi
        done

        if [ $removed -eq 0 ]; then
            echo "No unused remotes to clean up"
        else
            echo "Cleaned up $removed remote(s)"
        fi
    fi
}
