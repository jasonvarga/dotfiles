alias php='valet php'
alias composer='valet composer'

alias phpunit='vendor/bin/phpunit'
alias p='phpunit'
alias pf='p --filter'
alias ps='p --cache-result --order-by=depends,defects --stop-on-defect --stop-on-error --stop-on-failure'

alias comp='composer'
alias comp1="composer self-update --1 && composer --version"
alias comp2="composer self-update --2 && composer --version"

compv() {
  if [[ $1 == *"/"* ]]; then
    composer show $1 | grep 'versions' | grep -o -E '\*\ .+' | cut -d' ' -f2 | cut -d',' -f1;
  else
    composer info | grep $1
  fi
}

alias mix='npm run dev'
alias mw='npm run watch'
alias imix='npm install && mix'
alias cmix='npm ci && mix'
alias imw='npm install && mw'
alias cmw='npm ci && mw'

alias b='valet open' # browse
alias vapor='vendor/bin/vapor'

alias rray='comp require spatie/laravel-ray'
alias cr='ray -C' # clear ray

alias ts='open-docker && takeout start'
alias nginxlog='tail -f ~/.config/valet/Log/nginx-error.log'

# Read DB creds from .env file and open in TablePlus
opendb () {
   [ ! -f .env ] && { echo "No .env file found."; return 1; }

   DB_CONNECTION=$(grep DB_CONNECTION .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_HOST=$(grep DB_HOST .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_PORT=$(grep DB_PORT .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_DATABASE=$(grep DB_DATABASE .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_USERNAME=$(grep DB_USERNAME .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_PASSWORD=$(grep DB_PASSWORD .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)

   DB_URL="${DB_CONNECTION}://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_DATABASE}"

   echo "Opening ${DB_URL}"
   open $DB_URL
}

# Open Docker and wait for it to be ready
open-docker() {
  if (! docker stats --no-stream &> /dev/null); then
    echo "Waiting for Docker..."
    open --background -a Docker
    while (! docker stats --no-stream &> /dev/null); do
      sleep 1
    done
  fi
}
