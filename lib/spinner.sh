# Spinner function
sp="/-\|"
sc=0
spin() {
    printf "\b${sp:sc++:1}"
    ((sc == ${#sp})) && sc=0
}

endspin() {
    printf "\r%s\n" "$@"
}
