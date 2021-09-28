alias artisan='php artisan'
alias art='artisan'
alias acc='art cache:clear'
alias arte="[ -f .env ] || cp .env.example .env"
alias arti='comp install && arte && art key:generate && vo'
alias mfs='art migrate:fresh --seed'
alias queue='art queue:listen'
alias tink='tinker'

function tinker {
	if [ -e artisan ]; then
		php artisan tinker
	elif [ -e please ]; then
		php please tinker
	else
		psysh
	fi
}
