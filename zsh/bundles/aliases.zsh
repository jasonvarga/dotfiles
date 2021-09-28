alias c='clear'
alias artisan='php artisan'
alias please='php please'
alias art='artisan'
alias plz='please'
alias acc='art cache:clear'
alias asc='plz stache:clear'
alias phpunit='vendor/bin/phpunit'
alias p='phpunit'
alias pf='p --filter'
alias pc='p --cache-result --order-by=depends,defects --stop-on-defect'
alias pegs='p --exclude-group slow'
alias mfs='art migrate:fresh --seed'
alias comp='composer'
alias cucms='comp update statamic/cms'
alias crcms='comp require statamic/cms'
alias cmspath='comp show statamic/cms --path'
alias newsite='comp install && cp .env.example .env && art key:generate && vo'
alias vapor='vendor/bin/vapor'
alias flushdns='dscacheutil -flushcache'
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
alias cmix='npm ci && mix'
alias imw='npm install && mw'
alias cmw='npm ci && mw'
alias gs='git status'
alias gss='gs -s'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gcod='gco $(gdb)'
alias gap="git add -p"
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpsh='git push'
alias gnb='gco -b'
alias nah='git reset --hard; git clean -df;'
alias glt='git describe --tags --abbrev=0'
alias gt='gittower .'
alias gdb='git remote show origin | grep "HEAD branch" | cut -d " " -f5'
alias gdbardpl='gdbard && gpl'
alias gpr='gh pr checkout'
alias wip="git add . && git commit -m 'wip'"
alias wipa="git add . && git commit --amend -m 'wip'"
alias cdr='cd $(git rev-parse --show-toplevel)'
alias rray='comp require spatie/laravel-ray'
alias cr='ray -C'
alias tink='tinker'
alias sizes='du -sh -c *'
alias vo='valet open'
alias iterm='open . -a iterm'
alias bs='brew services'
alias sbs='sudo brew services'
alias nginxlog='tail -f ~/.config/valet/Log/nginx-error.log'
alias docker='open --background -a Docker'
eval $(thefuck --alias)