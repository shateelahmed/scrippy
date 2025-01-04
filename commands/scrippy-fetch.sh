#!/bin/bash

# This script runs "git fetch --all --prune" in each directory residing in its parent directory (default) or in the given directory

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Convert long options to short ones
for arg in "$@"; do
    shift
    case "$arg" in
    "--directory")
        set -- "$@" "-d" # Convert --directory to -d
        ;;
    *)
        set -- "$@" "$arg"
        ;; # Pass through the original argument if no match
    esac
done

# Use getopts for short options
while getopts "d:" opt; do
    case $opt in
    d)
        target_directory="$OPTARG"
        ;;
    esac
done

for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

echo -e "Target directory: ${green}$target_directory${reset}\n"

source "$script_location/lib/clear-proxy.sh"

# Get the list of directories
directories=($(ls -d "$target_directory"/*/))

# Total number of directories
total_dirs=${#directories[@]}
count=0

while true; do
    spin
    sleep 0.1
done &
# Run git fetch in all directories and show spinner animation during fetch
for child_directory in "${directories[@]}"; do
    if [ ! -d "$child_directory/.git" ]; then
        # Skip non-git directories
        continue
    fi

    child_directory_name=$(basename "$child_directory")

    # Start spinner in background


    # Capture the output of git fetch
    output=$(git -C "$child_directory" fetch --all --prune 2>&1)

    # Kill the spinner once git fetch completes

    # After git fetch completes, check if it was successful
    if [ $? -eq 0 ]; then
        if [[ -z "$output" ]]; then
            changes=$(echo "* No new changes were fetched." | sed 's/^/        /') # Properly format multi-line output
        else
            changes=$(echo "$output" | sed 's/^/        /') # Properly format multi-line output
        fi

        echo -e "${green}✔ Directory: $child_directory_name${reset}"
        echo "    - Changes:"
        echo "$changes"
        echo "    - Status: ${green}fetching done${reset}"
    else
        echo -e "${red}✘ Directory: $child_directory_name${reset}"
        echo "    - Changes:"
        echo "        * Error occurred during fetch."
        echo "    - Status: ${red}fetching failed${reset}"
    fi
    echo -e "\n"


    count=$((count + 1))
done
kill $!

# Ensure the spinner is stopped after the final fetch
endspin
