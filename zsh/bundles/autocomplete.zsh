zstyle ':autocomplete:*' widget-style menu-select
zstyle ':autocomplete:*' fzf-completion yes
zstyle ':autocomplete:*' list-lines 5
zstyle ':autocomplete:*' min-delay 0.2

# overriding this method so directory listing isn't shown on an empty prompt.
# simply commenting out the autocd behaviot.
# https://github.com/marlonrichert/zsh-autocomplete/discussions/308#discussioncomment-1025233
_autocomplete.config.tag-order() {
    local -aU tags=()
    [[ -n "$path[(r).]" ]] &&
        tags+=( globbed-files executables directories )
    [[ -o autocd ]] &&
        # tags+=( '(|local-)directories' )
    [[ -n $tags ]] &&
        tags+=( suffix-aliases )
    reply=( "$tags" ${${:-$PREFIX$SUFFIX}:--} )
}
