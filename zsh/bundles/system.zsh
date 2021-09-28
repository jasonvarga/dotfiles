alias flushdns='dscacheutil -flushcache'
alias ip='curl icanhazip.com'
alias ip4='curl ipv4.icanhazip.com'
alias ip6='curl ipv6.icanhazip.com'

mostusedcommands() {
    history | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head -15
}
