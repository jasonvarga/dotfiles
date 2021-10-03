alias please='php please'
alias plz='please'
alias asc='plz stache:clear'
alias pegs='p --exclude-group slow'
alias cucms='comp update statamic/cms'
alias cmspath='comp show statamic/cms --path'
alias s1='cd ~/code/statamic/one'
alias s2='cd ~/code/statamic/two'
alias s3='cd ~/code/statamic/three'
alias plzuser="cp $DOTFILES/statamic/jason@statamic.com.yaml users/jason@statamic.com.yaml && echo 'User created.'"
alias plzpro="sed -i \"\" \"s/'pro'\ =>\ false/'pro'\ =>\ true/\" config/statamic/editions.php && echo 'Pro enabled.'"

function linkcp {
    rm -f public/vendor/statamic/cp
    ln -s /Users/jason/Code/statamic/three/cms/resources/dist public/vendor/statamic/cp
}

function crcms() {
    branch=$(cd ~/code/statamic/three/cms && git rev-parse --abbrev-ref HEAD)
    if [[ $branch =~ ^[0-9]+\.[0-9]+$ ]]; then
        constraint="$branch.x-dev"
    else
        constraint="dev-$branch"
    fi
    command="composer require \"statamic/cms $constraint\""
    echo $command
    eval $command
}
