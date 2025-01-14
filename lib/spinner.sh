# Spinner function
sp="/-\|"
sc=0
spin() {
    while true; do
        printf "\r%s" "${sp:sc++:1}"  # Spinner character overwrite
        ((sc == ${#sp})) && sc=0
        sleep 0.1
    done
}

endspin() {
    kill "$1" 2>/dev/null  # Stop the spinner background process
    printf "\r\033[K"       # Clear the line (remove spinner output)
    printf "%s\n" "$@"      # Print optional message
    kill $!
}

trap 'endspin; exit' SIGINT SIGTERM
