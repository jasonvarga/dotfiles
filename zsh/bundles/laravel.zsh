function artisan() {
    php artisan "$@"
}

alias art='artisan'
alias acc='art cache:clear'
alias avp='art vendor:publish'
alias arte="[ -f .env ] || cp .env.example .env"
alias arti='comp install && arte && art key:generate && b'
alias arl='art route:list --except-path="cp,img,!,_debugbar,_ignition,sanctum"'
alias arla='art route:list'
alias mfs='art migrate:fresh --seed'
alias queue='art queue:listen'
alias tink='tinker'
alias sail='vendor/bin/sail'

# Open the current directory in Tinkerwell
function tinker {
    # Get the base64 encoded current working directory
    dir=$(echo -n $PWD | base64)
    open "tinkerwell://?cwd=$dir"
}

function laravel-new-sail {
    # exit if there's no argument
    if [ -z "$1" ]; then
        echo "App name required"
        return 1
    fi
    open-docker
    curl -s "https://laravel.build/$1" | bash
}
