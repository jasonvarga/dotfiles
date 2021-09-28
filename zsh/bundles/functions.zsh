# Switches to the default branch and deletes the branch it was just on.
# gdbard = "Git Delete Branch And Return to Default"
function gdbard {
    branch=$(git branch --show-current)
    default_branch=$(gdb)
    git checkout $default_branch
    git branch -D $branch
}

function tinker {
	if [ -e artisan ]; then
		php artisan tinker
	elif [ -e please ]; then
		php please tinker
	else
		psysh
	fi
}


function linkcp {
    rm -f public/vendor/statamic/cp
    ln -s /Users/jason/Code/statamic/three/cms/resources/dist public/vendor/statamic/cp
}


opendb () {
   [ ! -f .env ] && { echo "No .env file found."; exit 1; }

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


compv() {
  if [[ $1 == *"/"* ]]; then
    composer show $1 | grep 'versions' | grep -o -E '\*\ .+' | cut -d' ' -f2 | cut -d',' -f1;
  else
    composer info | grep $1
  fi
}

# Git checkout with fzf
gco() {
  if [ -n "$1" ]; then git checkout $1; return; fi
  local branches branch
  branches=$(git branch -vv)
  branch=$(echo "$branches" | fzf +m)
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# Commit with message
gc() {
  git commit -m "$*"
}

