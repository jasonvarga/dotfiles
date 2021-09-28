alias artisan='php artisan'
alias art='artisan'
alias acc='art cache:clear'
alias mfs='art migrate:fresh --seed'
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
