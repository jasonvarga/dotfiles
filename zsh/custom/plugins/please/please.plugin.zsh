# Statamic Please command completion
# A copy of the Laravel Artisan command, but for "please"

# Functions
_please_get_command_list () {
    php please \
    	| sed "1,/Available commands/d" \
    	| awk '/^  [a-z]+/ { print $1 }'
}

_please () {
    if [ -f artisan ]; then
        compadd `_please_get_command_list`
    fi
}

# Functions
please_init () {

}

# Completion setup
compdef _please php please
compdef _please please

# Alias
alias please='php please'
