# Creates a local branch from a Pull Request
# e.g. `gpr 123` would grab PR#123, put it in pull/123, and check it out.
function gpr {
    if [ -z "$1" ]; then
        echo "Usage: gpr <pr number>"
        return
    fi

    branch=pull/$1

    git fetch origin pull/$1/head:$branch
    git checkout $branch
}

# Switches to the master branch and deletes the pull request branch it was just on.
function gpr-del {
    branch=$(git branch --show-current)

    git checkout master

    if [[ $branch == pull/* ]]; then
        git branch -D $branch
    else
        echo "Not a pull/* branch, not deleting."
    fi
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
