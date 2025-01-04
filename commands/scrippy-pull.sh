#!/bin/bash

# Get the script's location
script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Convert long options to short ones
for arg in "$@"; do
    shift
    case "$arg" in
    "--directory")
        set -- "$@" "-d"
        ;;
    "--clear-proxy")
        set -- "$@" "-c"
        ;;
    *)
        set -- "$@" "$arg"
        ;;
    esac
done

clear_proxy=false

# Use getopts for short options
while getopts "d:c" opt; do
    case $opt in
    d)
        target_directory="$OPTARG"
        ;;
    c)
        clear_proxy=true
        ;;
    esac
done

# Handle positional arguments
shift $((OPTIND - 1))
arguments=("$@")
required_number_of_arguments=1
if [ "${#arguments[@]}" -ne "$required_number_of_arguments" ]; then
    echo "1 argument required. ${#arguments[@]} provided."
    exit 1
fi

# Load libraries if needed
for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

branch_to_pull="${arguments[0]}"

# Display initial details
echo -e "Target directory    : ${green}${target_directory}${reset}"
echo -e "Branch to pull      : ${green}${branch_to_pull}${reset}"
echo -e "Clear proxy         : ${green}${clear_proxy}${reset}\n"


while true; do
    spin
    sleep 0.1
done &

# Helper function to display status
show_status() {
    local dir_name=$1
    local status=$2
    local changes=$3

    if [ "$status" == "success" ]; then
        echo -e "${green}✔ Directory: $dir_name${reset}"
        echo -e "     - changes:"
        echo -e "           $changes"  # Ensure proper indentation
        echo -e "     - status: ${green}Successfully pulled ${branch_to_pull}${reset}\n\n"
    else
        echo -e "${red}✘ Directory: $dir_name${reset}"
        echo -e "     - changes:"
        echo -e "           $changes"  # Ensure proper indentation
        echo -e "     - status: ${red}Failed to pull ${branch_to_pull}${reset}\n\n"
    fi
}

# Iterate over each subdirectory
for child_directory in "$target_directory"/*/; do
    child_directory_name=$(basename "$child_directory")

    # Skip if not a Git repository
    if [ ! -d "$child_directory/.git" ]; then
        show_status "$child_directory_name" "failure" "Not a Git repository"
        continue
    fi

    # Check if the branch exists remotely
    git -C "$child_directory" ls-remote --heads origin "$branch_to_pull" &>/dev/null
    if [ $? -ne 0 ]; then
        show_status "$child_directory_name" "failure" "Branch ${branch_to_pull} not found on remote"
        continue
    fi

    # Fetch updates
    fetch_output=$(git -C "$child_directory" fetch --all --prune 2>&1)

    # Switch branch if needed
    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$branch_to_pull" ]; then
        git -C "$child_directory" checkout "$branch_to_pull" &>/dev/null
        current_branch=$(git -C "$child_directory" branch --show-current)
    fi

    if [ "$current_branch" != "$branch_to_pull" ]; then
        show_status "$child_directory_name" "failure" "Failed to switch to branch ${branch_to_pull}"
        continue
    fi

    # Pull changes
    pull_output=$(git -C "$child_directory" pull 2>&1)
    if [ $? -eq 0 ]; then
        show_status "$child_directory_name" "success" "$pull_output"
    else
        show_status "$child_directory_name" "failure" "$pull_output"
    fi
done

kill $!

# Ensure the spinner is stopped after the final fetch
endspin
