alias c='clear'
alias artisan='php artisan'
alias please='php please'
alias art='artisan'
alias plz='please'
alias acc='art cache:clear'
alias pcc='plz cache:clear'
alias phpunit='vendor/bin/phpunit'
alias p='phpunit'
alias pf='p --filter'
alias pc='p --cache-result --order-by=depends,defects --stop-on-defect'
alias pegs='p --exclude-group slow'
alias mfs='art migrate:fresh --seed'
alias comp='composer'
alias vapor='vendor/bin/vapor'
alias ip='curl icanhazip.com'
alias ip4='curl v4.icanhazip.com'
alias ip6='curl v6.icanhazip.com'
alias ls="ls -aFG"
alias l="ls"
alias rm="trash"
alias weather='curl -s wttr.in | sed -n "1,7p"'
alias dot='cd ~/.dotfiles'
alias o='open .'
alias sites='cd ~/Sites'
alias s1='cd ~/code/statamic/one'
alias s2='cd ~/code/statamic/two'
alias s3='cd ~/code/statamic/three'
alias mix='npm run dev'
alias mw='npm run watch'
alias imix='npm install && mix'
alias imw='npm install && mw'
alias gs='git status'
alias gss='gs -s'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gc="git commit -m"
alias gco="git checkout"
alias gcod='gco $(gdb)'
alias gap="git add -p"
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpsh='git push'
alias nah='git reset --hard; git clean -df;'
alias glt='git describe --tags --abbrev=0'
alias gt='gittower .'
alias gdb='git remote show origin | grep "HEAD branch" | cut -d " " -f5'
alias gpr='gh pr checkout'
alias wip="git add . && git commit -m 'wip'"
alias wipa="git add . && git commit --amend -m 'wip'"
alias cdr='cd $(git rev-parse --show-toplevel)'
alias ray='comp require spatie/laravel-ray'
alias tink='tinker'
alias sizes='du -sh -c *'
