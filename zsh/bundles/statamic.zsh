alias please='php please'
alias plz='please'
alias asc='plz stache:clear'
alias pegs='p --exclude-group slow'
alias cucms='comp update statamic/cms'
alias cmspath='comp show statamic/cms --path'
alias cms='cd ~/code/statamic/cms'
alias plzuser="cp $DOTFILES/statamic/jason@statamic.com.yaml users/jason@statamic.com.yaml && echo 'User created.'"
alias plzpro="sed -i \"\" \"s/'pro'\ =>\ false/'pro'\ =>\ true/\" config/statamic/editions.php && echo 'Pro enabled.'"
alias changelog='gcslt && gcslt | pbcopy'

function plzlink {
    if [ -d "public/vendor/statamic/cp" ]; then
        rm -f public/vendor/statamic/cp
    fi
    mkdir -p public/vendor/statamic
    ln -s /Users/jason/Code/statamic/cms/resources/dist public/vendor/statamic/cp
}

function crcms() {
    tag=$(cms && glt)
    tag=${tag#v}
    branch=$(cms && git rev-parse --abbrev-ref HEAD)
    if [[ $branch =~ ^[0-9]+\.[0-9]+$ ]]; then
        constraint="$branch.x-dev"
    elif [[ $branch =~ ^[0-9]+\.x+$ ]]; then
        constraint="$branch-dev"
    else
        constraint="dev-$branch"
    fi
    command="composer require \"statamic/cms $constraint as $tag\" -w $@"
    echo $command
    eval $command
}
