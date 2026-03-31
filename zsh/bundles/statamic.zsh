alias please='php please'
alias plz='please'
alias asc='plz stache:clear'
alias pegs='p --exclude-group slow'
alias cucms='comp update statamic/cms'
alias cmspath='comp show statamic/cms --path'
alias cms='cd ~/code/statamic/cms'
alias plzuser="cp $DOTFILES/statamic/jason@statamic.com.yaml users/jason@statamic.com.yaml && echo 'User created.'"
alias changelog='gcslt && gcslt | pbcopy'

function plzpro {
    if grep -q "env('STATAMIC_PRO_ENABLED'" config/statamic/editions.php 2>/dev/null; then
        if grep -q "^STATAMIC_PRO_ENABLED=" .env 2>/dev/null; then
            sed -i "" "s/^STATAMIC_PRO_ENABLED=.*/STATAMIC_PRO_ENABLED=true/" .env
        else
            echo "STATAMIC_PRO_ENABLED=true" >> .env
        fi
    else
        sed -i "" "s/'pro' => false/'pro' => true/" config/statamic/editions.php
    fi
    echo 'Pro enabled.'
}

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
