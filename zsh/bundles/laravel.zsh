alias artisan='php artisan'
alias art='artisan'
alias acc='art cache:clear'
alias avp='art vendor:publish'
alias arte="[ -f .env ] || cp .env.example .env"
alias arti='comp install && arte && art key:generate && b'
alias mfs='art migrate:fresh --seed'
alias queue='art queue:listen'
alias tink='tinker'
alias sail='vendor/bin/sail'

function tinker {
	if [ -e artisan ]; then
		php artisan tinker
	elif [ -e please ]; then
		php please tinker
	else
		psysh
	fi
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
